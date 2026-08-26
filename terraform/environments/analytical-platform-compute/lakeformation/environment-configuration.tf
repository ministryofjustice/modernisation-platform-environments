locals {
  environment_configurations = {
    development = {

      /* EKS */
      eks_sso_access_role = "modernisation-platform-sandbox"

    }
    test = {

      /* EKS */
      eks_sso_access_role = "modernisation-platform-developer"

    }
    production = {

      /* EKS */
      eks_sso_access_role = "modernisation-platform-developer"

      /* LF Domain Tags */
      cadet_lf_tags = {
        domain = [
          "bold",
          "cica",
          "cjs_cross_dataset",
          "civil",
          "corporate",
          "counter_terrorism",
          "courts",
          "criminal_history",
          "data_first",
          "development_sandpit",
          "electronic_monitoring",
          "family",
          "finance",
          "general",
          "interventions",
          "laa",
          "opg",
          "people",
          "performance",
          "prison",
          "probation",
          "property",
          "public",
          "risk",
          "sentence_offence",
          "staging",
          "victims",
          "victims_case_management",
          "radsai_segmentation"
        ]
      }
    }
  }
}
