<?xml version="1.0" encoding="UTF-8"?>
<PwmConfiguration pwmVersion="2.0.6" xmlVersion="4" createTime="1970-01-01T00:00:00Z">
  <localeBundle bundle="password.pwm.i18n.Display" key="Title_Application">
    <value><![CDATA[National Delius - Account Self Service]]></value>
  </localeBundle>
  <localeBundle bundle="password.pwm.i18n.Display" key="Display_RecoverTokenSendOneChoice">
    <value><![CDATA[To verify your identity, press the Continue button to send a security code to %1%.]]></value>
  </localeBundle>
  <properties type="config">
    <!-- Set saveConfigOnStart=true to encrypt plaintext passwords on startup -->
    <property key="saveConfigOnStart">true</property>
    <property key="configPasswordHash">$${CONFIG_PASSWORD_HASH}</property>
    <property key="configIsEditable">false</property>
    <property key="configEpoch">1</property>
  </properties>
  <settings>
    <setting key="pwm.securityKey" syntax="PASSWORD">
      <label>Security Key</label>
      <value plaintext="true">$${SECURITY_KEY}</value>
    </setting>
     <setting key="pwm.appProperty.overrides" modifyTime="2023-10-24T00:19:49Z" syntax="STRING_ARRAY" syntaxVersion="0">
    <label>Settings ⇨ Application ⇨ Application ⇨ App Property Overrides</label>
    <value>security.http.permittedUrlPathCharacters=^[a-zA-Z0-9-_=\\s]*$</value>
  </setting>
    <setting key="template.ldap" syntax="SELECT">
      <label>LDAP Vendor Default Settings</label>
      <value><![CDATA[OPEN_LDAP]]></value>
    </setting>
    <setting key="template.storage" syntax="SELECT">
      <label>Storage Default Settings</label>
      <value><![CDATA[LDAP]]></value>
    </setting>
    <setting key="ldap.profile.list" syntax="PROFILE" profile="default">
      <label>LDAP Directory Profiles</label>
      <value><![CDATA[default]]></value>
    </setting>
    <setting key="ldap.serverUrls" syntax="STRING_ARRAY" profile="default">
      <label>LDAP URLs</label>
      <value><![CDATA[${ldap_host_url}]]></value>
    </setting>
    <setting key="ldap.proxy.username" syntax="STRING" profile="default">
      <label>LDAP Proxy User</label>
      <value><![CDATA[cn=admin,dc=moj,dc=com]]></value>
    </setting>
    <setting key="ldap.proxy.password" syntax="PASSWORD" profile="default">
      <label>LDAP Proxy Password</label>
      <value plaintext="true">$${LDAP_PASSWORD}</value>
    </setting>
    <setting key="ldap.rootContexts" syntax="STRING_ARRAY" profile="default">
      <label>LDAP Contextless Login Roots</label>
      <value><![CDATA[ou=Users,dc=moj,dc=com]]></value>
    </setting>
    <setting key="ldap.guidAttribute" syntax="STRING" profile="default">
      <label>LDAP GUID Attribute</label>
      <value><![CDATA[uid]]></value>
    </setting>
    <setting key="ldap.testuser.username" syntax="STRING" profile="default">
      <label>LDAP Test User</label>
      <value><![CDATA[cn=pwm-test,ou=Users,dc=moj,dc=com]]></value>
    </setting>
    <setting key="pwmAdmin.queryMatch" syntax="USER_PERMISSION" syntaxVersion="2">
      <label>Administrator Permission</label>
      <value>{"ldapBase":"ou=Users,dc=moj,dc=com","ldapQuery":"(pwmAdmin=TRUE)","type":"ldapQuery"}</value>
    </setting>
    <setting key="pwm.publishStats.enable" syntax="BOOLEAN">
      <label>Enable Anonymous Statistics Publishing</label>
      <value>false</value>
    </setting>
    <setting key="pwm.publishStats.siteDescription" syntax="STRING">
      <label>Site Description</label>
      <value />
    </setting>
    <setting key="pwm.selfURL" syntax="STRING">
      <label>Site URL</label>
      <value><![CDATA[${pwm_url}]]></value>
    </setting>
    <setting key="pwm.introURL" syntax="SELECT">
      <label>Intro URL</label>
      <value><![CDATA[/public/forgottenpassword]]></value>
    </setting>
    <setting key="display.showDetailedErrors" syntax="BOOLEAN">
      <label>Show Detailed Error Messages</label>
      <value>false</value>
    </setting>
    <setting key="display.idleTimeout" syntax="BOOLEAN">
      <label>Show Idle Timeout Counter</label>
      <value>true</value>
    </setting>
    <setting key="display.accountInformation" syntax="BOOLEAN">
      <label>Show User Account Information</label>
      <value>true</value>
    </setting>
    <setting key="accountInfo.viewStatusValues" syntax="OPTIONLIST">
      <label>Viewable Status Fields</label>
      <value>PasswordSetTime</value>
      <value>PasswordSetTimeDelta</value>
      <value>PasswordViolatesPolicy</value>
      <value>UserEmail</value>
      <value>UserSMS</value>
      <value>Username</value>
    </setting>
    <setting key="recovery.verificationMethods" syntax="VERIFICATION_METHOD" profile="default">
      <label>Verification Methods</label>
      <value><![CDATA[{"methodSettings":{"PREVIOUS_AUTH":{"enabledState":"disabled"},"ATTRIBUTES":{"enabledState":"disabled"},"CHALLENGE_RESPONSES":{"enabledState":"disabled"},"TOKEN":{"enabledState":"required"},"OTP":{"enabledState":"disabled"},"REMOTE_RESPONSES":{"enabledState":"disabled"},"OAUTH":{"enabledState":"disabled"}},"minOptionalRequired":0}]]></value>
    </setting>
    <setting key="challenge.enable" syntax="BOOLEAN">
      <label>Enable Setup Responses</label>
      <value>false</value>
    </setting>
    <setting key="challenge.forceSetup" syntax="BOOLEAN">
      <label>Force Response Setup</label>
      <value>false</value>
    </setting>
    <setting key="password.policy.source" syntax="SELECT">
      <label>Password Policy Source</label>
      <value><![CDATA[PWM]]></value>
    </setting>
    <setting key="password.policy.caseSensitivity" syntax="SELECT">
      <label>Password is Case Sensitive</label>
      <value><![CDATA[true]]></value>
    </setting>
    <setting key="password.policy.minimumLength" syntax="NUMERIC" profile="default">
      <label>Minimum Length</label>
      <value>8</value>
    </setting>
    <setting key="password.policy.allowNumeric" syntax="BOOLEAN" profile="default">
      <label>Allow Numeric Characters</label>
      <value>true</value>
    </setting>
    <setting key="password.policy.allowSpecial" syntax="BOOLEAN" profile="default">
      <label>Allow Special Characters</label>
      <value>true</value>
    </setting>
    <setting key="password.policy.maximumUpperCase" syntax="NUMERIC" profile="default">
      <label>Maximum Uppercase</label>
      <default />
    </setting>
    <setting key="password.policy.maximumLowerCase" syntax="NUMERIC" profile="default">
      <label>Maximum Lowercase</label>
      <default />
    </setting>
    <setting key="password.policy.disallowCurrent" syntax="BOOLEAN" profile="default">
      <label>Disallow Current Password</label>
      <value>false</value>
    </setting>
    <setting key="password.policy.disallowedValues" syntax="STRING_ARRAY" profile="default">
      <label>Disallowed Values</label>
      <value />
    </setting>
    <setting key="email.smtp.address" syntax="STRING" profile="default">
      <label>SMTP Server Address</label>
      <value><![CDATA[${email_smtp_address}]]></value>
    </setting>
    <setting key="email.default.fromAddress" syntax="STRING">
      <label>Default From Address</label>
      <value><![CDATA[${email_from_address}]]></value>
    </setting>
    <setting key="network.allowMultiIPSession" syntax="BOOLEAN">
      <label>Allow Roaming Source Network Address</label>
      <value>true</value>
    </setting>
    <setting key="intruder.enable" syntax="BOOLEAN">
      <label>Enable PWM Intruder Detection</label>
      <value>false</value>
    </setting>
    <setting key="security.ldap.simulateBadPassword" syntax="BOOLEAN">
      <label>Enable Bad Password Simulation</label>
      <value>false</value>
    </setting>
    <setting key="enableSessionVerification" syntax="SELECT">
      <label>Sticky Session Verification</label>
      <value><![CDATA[OFF]]></value>
    </setting>
    <setting key="token.storageMethod" syntax="SELECT">
      <label>Token Storage Method</label>
      <value><![CDATA[STORE_LOCALDB]]></value>
    </setting>
    <setting key="token.length" syntax="SELECT">
      <label>Token Length</label>
      <value><![CDATA[64]]></value>
    </setting>
    <setting key="email.smtp.type" syntax="SELECT">
      <label>SMTP Connection Type</label>
      <value><![CDATA[START_TLS]]></value>
    </setting>
    <setting key="email.smtp.username" syntax="PASSWORD">
      <label>SMTP Server User Name</label>
      <value><![CDATA[$${SES_USERNAME}]]></value>
    </setting>
    <setting key="email.smtp.userpassword" syntax="STRING">
      <label>SMTP Server Password</label>
      <value plaintext="true"><![CDATA[$${SES_PASSWORD}]]></value>
    </setting>
    <setting key="email.smtp.port" syntax="NUMERIC">
      <label>SMTP Server Port</label>
      <value>587</value>
    </setting>
  </settings>
</PwmConfiguration>