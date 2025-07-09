from airflow.www.utils import UIAlert
from kubernetes.client import models as k8s


DASHBOARD_UIALERTS = [
    UIAlert(
        'Analytical Platform Airflow Service',
        category="info",
        html=True,
    )
]


# override PodDefaults, specifically SIDECAR_CONTAINER.image and SIDECAR_CONTAINER.security_context

class PodDefaults:
  """Static defaults for Pods."""

  XCOM_MOUNT_PATH = "/airflow/xcom"
  SIDECAR_CONTAINER_NAME = "airflow-xcom-sidecar"
  XCOM_CMD = 'trap "exit 0" INT; while true; do sleep 1; done;'
  VOLUME_MOUNT = k8s.V1VolumeMount(name="xcom", mount_path=XCOM_MOUNT_PATH)
  VOLUME = k8s.V1Volume(name="xcom", empty_dir=k8s.V1EmptyDirVolumeSource())
  SIDECAR_CONTAINER = k8s.V1Container(
    name=SIDECAR_CONTAINER_NAME,
    command=["sh", "-c", XCOM_CMD],
    image="ghcr.io/ministryofjustice/analytical-platform-airflow-xcom-sidecar:1.0.0-rc1@sha256:4378d3e223747478b63c3fb2a262e201e12b0ddc997c8e62f2eecae365b28021",
    volume_mounts=[VOLUME_MOUNT],
    resources=k8s.V1ResourceRequirements(
      requests={
          "cpu": "1m",
          "memory": "10Mi",
      },
    ),
    security_context = k8s.V1SecurityContext(
        allow_privilege_escalation=False,
        privileged=False,
        run_as_non_root=True,
        seccomp_profile=k8s_models.V1SeccompProfile(type="RuntimeDefault"),
        capabilities=k8s_models.V1Capabilities(drop=["ALL"]),
    ),
  )