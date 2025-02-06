--------------------------------------------------------------------------------------------------------------------
--
-- Archive:    %ARCHIVE%
-- Revision:   %PR%
-- Date:       %DATE%
--
-- Purpose: Modify warehouse tables to set column default values
--
--
-- Dimensions History
-- ------------------
--
-- Ver  Date     Name                 Description
-- ---- -------- -------------------- ------------------------------------------------------------------------------
-- 1.0  27/11/14 H Khela             Initial Version
--
--
--------------------------------------------------------------------------------------------------------------------
SPOOL maat_05365_ware_db_changes.log

-- Set time on so you can see how long each part takes
SET TIME ON

-- Set echo on so that you can see which command it is executing (and the time)
SET ECHO ON

ALTER TABLE warehouse.maat_assessment_fact MODIFY (
time_eff_to_dim_id NUMBER DEFAULT NULL);

ALTER TABLE warehouse.maat_application_dim MODIFY (
time_eff_to_dim_id NUMBER DEFAULT NULL);

  -- 9710356 rows updated.

  UPDATE warehouse.maat_assessment_fact
  SET time_eff_to_dim_id = NULL
  WHERE time_eff_to_dim_id = -1;

  COMMIT;

  -- 4558089 rows updated

  UPDATE warehouse.maat_application_dim
  SET time_eff_to_dim_id = NULL
  WHERE time_eff_to_dim_id = -1;

COMMIT;

SPOOL OFF