# Synthetic Data Generator - Gatling with Kafka

A Java 21 Maven project that runs Gatling load test simulations and publishes events to Apache Kafka in real-time.

## Prerequisites

- **Java 21** or later
- **Maven 3.8.1** or later
- **Docker & Docker Compose** (for Kafka and Kafka UI)

## Building the Project

Compile and package:

```bash
mvn clean package
```

## Testing with Docker Compose

### Step 1 - Start the stack

```bash
docker-compose -f src/e2e/docker-compose-local-setup.yml up -d --build
```

Verify services are running:

```bash
docker-compose -f src/e2e/docker-compose-local-setup.yml ps
```

---

## Step 2 - Running Simulations with Maven Gatling Plugin

### Run a Specific Simulation

---

### GeoFence

```bash
mvn gatling:test -Dgatling.simulationClass=simulation.geofence.HmpPerimeterSimulation -s /home/moj/ci-settings.xml
```

---

### Radar Sequence Events

| parameter name         | default value  | description                                                |
|------------------------|----------------|------------------------------------------------------------|
| hmpSite                | HMP-MANCHESTER | HMP site names                                             |
| scenarioId             | S01            | POV scenarios - S01, S02, S03, S04, S05                    |
| navigationSteps        | 8              | radar navigation steps from start to finish - 6, 8, 10, 12 |
| rateOfIngestionSeconds | 2              | radar event ingestion rate in seconds                      |

## `Scenario S01:` Drone flying into outer perimeter during daytime - Moderate drone threat alert

```bash
mvn -DhmpSite="HMP-MANCHESTER" -DscenarioId="S01" -DnavigationSteps=10 -DrateOfIngestionSeconds=2 gatling:test -Dgatling.simulationClass=simulation.radar.RadarSequenceSimulation -s /home/moj/ci-settings.xml
```

## `Scenario S02:` Drone flying into outer perimeter at 03:00 hrs - High drone threat alert

```bash
mvn -DhmpSite="HMP-MANCHESTER" -DscenarioId="S02" -DnavigationSteps=8 -DrateOfIngestionSeconds=2 gatling:test -Dgatling.simulationClass=simulation.radar.RadarSequenceSimulation -s /home/moj/ci-settings.xml
```

## `Scenario S03:` Drone flying into outer and inner perimeter at 03:00 hrs - High drone threat alert

```bash
mvn -DhmpSite="HMP-MANCHESTER" -DscenarioId="S03" -DnavigationSteps=8 -DrateOfIngestionSeconds=3 gatling:test -Dgatling.simulationClass=simulation.radar.RadarSequenceSimulation -s /home/moj/ci-settings.xml
```

### Correlated Sequence Events

| parameter name         | default value   | description                                                 |
|------------------------|-----------------|-------------------------------------------------------------|
| hmpSite                | HMP-LONG-LARTIN | HMP site names                                              |
| scenarioId             | S04             | POV scenarios - S01, S02, S03, S04, S05                     |
| navigationSteps        | 12              | radar navigation steps from start to finish - 6, 8, 10, 12  |
| rateOfIngestionSeconds | 2               | radar event ingestion rate in seconds                       |
| pauseSeconds           | 5               | pause between correlation events in seconds (radar and cdr) |

## `Scenario S04:` Drone flying into perimeter at 03:00 hrs and call made 5 seconds later matching number of interest - High drone threat alert

```bash
mvn -DhmpSite="HMP-LONG-LARTIN" -DscenarioId="S04" -DnavigationSteps=12 -DrateOfIngestionSeconds=3 -DpauseSeconds=10 gatling:test -Dgatling.simulationClass=simulation.correlated.CorrelatedSequenceS04Simulation -s /home/moj/ci-settings.xml
```

## `Scenario S05:` VoiceCall number from interestList (Forensic). 6 seconds later drone flying into perimeter - High drone threat alert

```bash
mvn -DhmpSite="HMP-LONG-LARTIN" -DscenarioId="S05" -DnavigationSteps=12 -DrateOfIngestionSeconds=3 -DpauseSeconds=3 gatling:test -Dgatling.simulationClass=simulation.correlated.CorrelatedSequenceS05Simulation -s /home/moj/ci-settings.xml
```

---

### Radar Heartbeat

```bash
mvn -DhmpSite="HMP-MANCHESTER" -Dusers=20 -DdurationSeconds=60 gatling:test -Dgatling.simulationClass=simulation.heartbeat.RadarHeartbeatSimulation -s /home/moj/ci-settings.xml
```

### All Radar data

```bash
mvn -DnavigationSteps=8 -DrateOfIngestionSeconds=2 gatling:test -Dgatling.simulationClass=simulation.radar.RadarSequenceALLSimulation -s /home/moj/ci-settings.xml
```

---




### Gatling Output

Maven prints simulation progress to stdout. You'll see:

- User ramp-up progress
- Request success/failure counts
- Response time statistics
- Simulation summary at the end

Example output:

```
Simulation simulation.radar.RadarRandomSimulation started...

================================================================================
2026-04-02 10:56:50 GMT                                       5s elapsed
---- Requests ------------------------------------------------------------------
> Global                                                   (OK=6      KO=0     )
> Radar Data                                               (OK=6      KO=0     )

---- Leeds[No Breach] radar events into kafka topic in 'local' -----------------
[############################################                              ] 60%
          waiting: 4      / active: 0      / done: 6     
================================================================================


================================================================================
2026-04-02 10:56:54 GMT                                       9s elapsed
---- Requests ------------------------------------------------------------------
> Global                                                   (OK=10     KO=0     )
> Radar Data                                               (OK=10     KO=0     )

---- Leeds[No Breach] radar events into kafka topic in 'local' -----------------
[##########################################################################]100%
          waiting: 0      / active: 0      / done: 10    
================================================================================

Simulation simulation.radar.RadarRandomSimulation completed in 9 seconds
```

### Step 3 - Stop the Stack

```bash
docker-compose -f src/e2e/docker-compose-local-setup.yml down -v --remove-orphans
```

## Resources

- [Gatling Documentation](https://gatling.io/docs/gatling/)
