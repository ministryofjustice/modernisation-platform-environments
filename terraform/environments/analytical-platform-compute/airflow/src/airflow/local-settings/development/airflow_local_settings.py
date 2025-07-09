from airflow.www.utils import UIAlert
from airflow.providers.cncf.kubernetes.utils.xcom_sidecar import PodDefaults
from kubernetes.client import models as k8s_models


DASHBOARD_UIALERTS = [
    UIAlert(
        'Analytical Platform Airflow Service',
        category="info",
        html=True,
    )
]

# Configure the XCom sidecar container
PodDefaults.SIDECAR_CONTAINER.image = "ghcr.io/ministryofjustice/analytical-platform-airflow-xcom-sidecar:1.0.0-rc1@sha256:4378d3e223747478b63c3fb2a262e201e12b0ddc997c8e62f2eecae365b28021"

PodDefaults.SIDECAR_CONTAINER.security_context=k8s_models.V1SecurityContext(
    allow_privilege_escalation=False,
    privileged=False,
    run_as_non_root=True,
    seccomp_profile=k8s_models.V1SeccompProfile(type="RuntimeDefault"),
    capabilities=k8s_models.V1Capabilities(drop=["ALL"]),
)
