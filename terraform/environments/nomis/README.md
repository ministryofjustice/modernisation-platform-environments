## Overview

This terraform project contains code for:
- NOMIS database
- NOMIS audit database
- NOMIS weblogic (legacy NOMIS frontend)

And supporting infrastructure:
- bastion (for ssh tunnelling to database)

The following environments are supported:
- development (e.g. syscon environment + infrastructure dev)
- test (main test environment + temporary environments as needed)
- preproduction (single environment for learning and preprod)
- production
