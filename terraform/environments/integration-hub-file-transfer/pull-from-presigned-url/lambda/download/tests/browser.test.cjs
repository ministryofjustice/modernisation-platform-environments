const {test} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const {join} = require('node:path');
const vm = require('node:vm');
const {webcrypto} = require('node:crypto');
const ID = 'a'.repeat(64);
const config = {client_id: 'public-client', authorization_endpoint: 'https://id.example/authorize',
  token_endpoint: 'https://id.example/token', download_scope: 'mft.download', redirect_uri: 'https://api.example/callback'};
const script = readFileSync(join(__dirname, '../index.html'), 'utf8').match(/<script[^>]*>([\s\S]*?)<\/script>/)[1]
  .replace('__SETTINGS__', Buffer.from(JSON.stringify(config)).toString('base64'));
const tick = () => new Promise(resolve => setImmediate(resolve));
function browser({callback=false, saved, search='?state=state&code=code', fetcher}={}) {
  const elements = {status: {}, action: {}};
  const storage = new Map(saved ? [['mft-login', JSON.stringify(saved)]] : []);
  const redirects = [], history = [], calls = [];
  const context = vm.createContext({crypto: webcrypto, TextEncoder, Uint8Array, URL, URLSearchParams, atob, btoa,
    document: {getElementById: id => elements[id]},
    location: {pathname: callback ? '/callback' : '/pickups/'+ID, search, assign: url => redirects.push(url)},
    history: {replaceState: (_, __, url) => history.push(url)},
    sessionStorage: {getItem: key => storage.get(key), setItem: (key, value) => storage.set(key, value), removeItem: key => storage.delete(key)},
    fetch: async (...args) => {calls.push(args); return fetcher(...args);}});
  vm.runInContext(script, context);
  return {elements, storage, redirects, history, calls};
}
const pending = () => ({verifier: 'verifier', state: 'state', pickupId: ID, created: Date.now()});
test('sign-in creates random one-time state and S256 PKCE bound to the pickup', async () => {
  const b = browser();
  await b.elements.action.onclick();
  const url = new URL(b.redirects[0]);
  const saved = JSON.parse(b.storage.get('mft-login'));
  assert.equal(url.origin, 'https://id.example');
  assert.equal(url.searchParams.get('code_challenge_method'), 'S256');
  assert.equal(url.searchParams.get('state'), saved.state);
  assert.equal(saved.pickupId, ID);
  assert.equal(url.searchParams.get('scope'), 'openid mft.download');
  assert.equal(url.searchParams.get('redirect_uri'), config.redirect_uri);
  assert.notEqual(url.searchParams.get('code_challenge'), saved.verifier);
});
test('callback rejects mismatched, expired or replayed state without token exchange', async () => {
  for (const saved of [undefined, {...pending(), state: 'different'}, {...pending(), created: Date.now()-700000}]) {
    const b = browser({callback:true, saved, fetcher: () => {throw new Error('must not fetch');}});
    await tick();
    assert.equal(b.calls.length, 0);
    assert.equal(b.storage.has('mft-login'), false);
    assert.match(b.elements.status.textContent, /expired/);
    assert.deepEqual(b.history, ['/callback']);
  }
});
test('successful callback uses access token only, waits for explicit download and never stores token', async () => {
  const b = browser({callback:true, saved:pending(), fetcher: async url => ({ok:true, status:200,
    json: async () => url === config.token_endpoint ? {access_token:'access', id_token:'identity', token_type:'Bearer'} :
      {url:'https://bucket.s3.eu-west-2.amazonaws.com/file?signature=secret', expiresIn:300}})});
  await tick();
  assert.equal(b.calls.length, 1);
  assert.equal(b.calls[0][1].body.get('code_verifier'), 'verifier');
  assert.equal(b.storage.size, 0);
  assert.equal(b.elements.action.textContent, 'Download file');
  await b.elements.action.onclick();
  assert.equal(b.calls[1][0], '/pickups/'+ID+'/download');
  assert.equal(b.calls[1][1].method, 'POST');
  assert.equal(b.calls[1][1].headers.Authorization, 'Bearer access');
  assert.equal(b.calls[1][1].credentials, 'omit');
  assert.equal(b.redirects.length, 1);
});
test('unauthorised recipient is never redirected to a download', async () => {
  const b = browser({callback:true, saved:pending(), fetcher: async url => url === config.token_endpoint ?
    {ok:true, json:async () => ({access_token:'access', token_type:'Bearer'})} : {ok:false, status:403}});
  await tick(); await b.elements.action.onclick();
  assert.equal(b.redirects.length, 0);
  assert.match(b.elements.status.textContent, /permission/);
});
test('callback cannot bind an attacker-controlled pickup path', async () => {
  const b = browser({callback:true, saved:{...pending(),pickupId:'../../other'}, fetcher: () => {throw new Error('must not fetch');}});
  await tick(); assert.equal(b.calls.length, 0); assert.equal(b.redirects.length, 0);
});
test('download response cannot redirect to another origin', async () => {
  const b = browser({callback:true, saved:pending(), fetcher: async url => ({ok:true, status:200,
    json:async () => url === config.token_endpoint ? {access_token:'access',token_type:'Bearer'} : {url:'https://evil.example/file'}})});
  await tick(); await b.elements.action.onclick();
  assert.equal(b.redirects.length, 0);
  assert.match(b.elements.status.textContent, /Unexpected download/);
});
