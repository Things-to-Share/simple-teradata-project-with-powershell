# Templ

## Introduction

This enterprise-grade, end-to-end data processing framework on Teradata SQL for regulatory reporting to the Single Resolution Board (SRB). This comprehensive solution orchestrates the complete data lifecycle from multi-source integration through CSV generation and SharePoint delivery, supporting Minimal Bail-in Data Templates (MBDT) submissions with full audit capabilities, temporal tracking, and automated deployment pipelines.

## Components of the Framework

The framework comprises seven interconnected layers working in harmony. The **Logging Framework** provides centralized monitoring through [`logging_tbl_log`](./logging/tables/tbl_log.md) and [`logging_tbl_debug`](./logging/tables/tbl_debug.md), capturing execution metrics and debug information via procedures like [`logging_usp_start`](./logging/procedures/usp_start.md) and [`logging_usp_finish`](./logging/procedures/usp_finish.md). The **Generic Framework** delivers reusable data operations including [`generic_usp_load_view_into_table`](./generic/procedures/usp_load_view_into_table.md) and [`generic_usp_hist_view_into_table`](./generic/procedures/usp_hist_view_into_table.md) with intelligent retry logic for transient errors. The **Metadata Framework** maintains comprehensive object catalogs through [`metadata_tbl_table`](./metadata/tables/metadata_tbl_table.md) and [`metadata_tbl_column`](./metadata/tables/metadata_tbl_column.md), supporting impact analysis and documentation.

The **Inbound Layer** consolidates data from DGS and SPAL MBDT sources via tables like [`fdwh1_dwhi_dgs_tbl_counterparties`](./fdwh1_dwhi_dgs/tables/tbl_counterparties.md) and [`fdwh2_spal_mbdt_tbl_main_liabilities`](./fdwh2_spal_mbdt/tables/fdwh2_spal_mbdt_tbl_main_liabilities.md). The **Intermediate Layer** performs union consolidation through [`union_of_tbl_aggregate_view`](./union_of/tables/union_of_tbl_aggregate_view.md) and CSV transformation via [`prep_csv_tbl_main_liabilities`](./prep_csv/tables/prep_csv_tbl_main_liabilities.md). The **Delivery Layer** manages export metadata in [`exports_tbl_file`](./exports/tables/exports_tbl_file.md), generating SRB-compliant filenames. Finally, the **PowerShell Automation Framework** orchestrates deployments and SharePoint exports across all environments.

## Key Features

**Multi-Source Data Integration** - Seamlessly consolidates data from two independent warehouses (fdwh1_dwhi_dgs and fdwh2_spal_mbdt) using intelligent union operations with source tracking and conflict prevention through row number offsetting.

**Comprehensive Metadata Management** - Every component implements standardized metadata attributes including SHA256 hashing (`meta_ch_rh`, `meta_ch_bk`, `meta_ch_pk`), temporal tracking (`meta_dt_tech_valid_start/ended`), and version control (`meta_is_actual`, `meta_ni_rn`) for complete auditability.

**Bitemporal Data Architecture** - Supports dual-time dimension tracking through business time (`functionalpit`) and technical validity timestamps, enabling point-in-time historical queries, regulatory time-travel analysis, and comprehensive audit trails.

**SCD Type 2 Historization** - Implements Slowly Changing Dimension patterns through [`generic_usp_hist_view_into_table`](./generic/procedures/usp_hist_view_into_table.md), maintaining complete data lineage with technical validity periods and actual record flags.

**Robust Error Handling** - Features intelligent retry logic in procedures like [`generic_usp_exec_dynamic_sql`](./generic/procedures/usp_exec_dynamic_sql.md), distinguishing transient errors (deadlocks, spool space) from critical failures with progressive backoff strategies.

**Automated CSV Generation** - The prep_csv layer automatically formats data with embedded headers, type-specific formatting, NULL handling, and quote wrapping, producing SRB-compliant exports with standardized naming: `TabCode_Country_LEI_SubmissionType_TimestampSubmission.csv`.

**Centralized Logging Framework** - All operations integrate with logging procedures creating hierarchical execution trees in [`logging_tbl_log`](./logging/tables/tbl_log.md), supporting performance analysis through [`logging_viw_log_with_duration`](./logging/views/viw_log_with_duration.md).

**Process Group Management** - [`metadata_viw_process_group`](./metadata/views/metadata_viw_process_group.md) enables logical organization of tables for ETL workflows, circular dependency detection, and optimized processing sequences.

**Environment-Specific Deployment** - PowerShell automation supports four environments (O/T/A/P) with differential deployment, automated schema comparison, and controlled rollback capabilities through build/publish phases.

**Hash-Based Change Detection** - SHA256 fingerprinting throughout the pipeline enables efficient data reconciliation, duplicate prevention, and impact analysis without column-by-column comparisons.

**Snapshot-Based Orchestration** - [`fdwh2_dwa_control_tbl_model_snapshot`](./fdwh2_dwa_control/tables/tbl_model_snapshot.md) and [`fdwh2_dwa_control_tbl_snapshot_persist_status`](./fdwh2_dwa_control/tables/tbl_snapshot_persist_status.md) coordinate data loading cycles with processing metrics and timing analysis.

**Dynamic SQL Execution** - [`generic_usp_exec_dynamic_sql`](./generic/procedures/usp_exec_dynamic_sql.md) handles complex view definitions including CTEs with comprehensive error handling and automatic retry mechanisms.

**Reference Detection** - [`metadata_viw_referenced`](./metadata/views/metadata_viw_referenced.md) automatically identifies table dependencies by parsing view definitions, supporting impact analysis and deployment ordering.

**Dual Storage Support** - [`exports_tbl_folder`](./exports/tables/exports_tbl_folder.md) maintains both server and SharePoint paths, enabling flexible deployment across different storage infrastructures with environment-specific configurations.

**Secure Credential Management** - PowerShell framework implements DPAPI-encrypted credential storage with optional override prompts, ensuring secure database authentication without hardcoded passwords.

---

**Utilized ASN GPT Prompt**

This was generated with "Complex Claude 4 sonnet"-version

<details>
<summary>the prompt</summary>

Act like a Teradat SQL expert: 
- Given the previous texts, create summary overview of the framework utilized by the Loantapes/DD-OSX team(s). Handle the following topics
- Leave out "${nm_database_target}" when referencing the procedure, table and/or view name(s) 
- virutal schema the part before "_tbl", "_viw_" of "_usp_" is the virual schema name
- If reference a SQL object make it into a clickable link to the documentation use this format "[`sql-object`](./<virtual-schema-name>/tables/<name-of-table>.md)" for tables and for procedure use "[`sql-object`](./<virtual-schema-name>/procedures/<name-of_procedure>.md)"

- The document structure handle the following topic, in the given order
  - Introduction (MAx 100 words, DO NOT make if longer then is required)
  - Components of the Framework more detailt text max 200 words
  - Key Features
  - 
- At the End of the document, add the following in the give order.
  - divider line
  - text **Utilized ASN GPT Prompt**
  - This was generated with "Complex Claud 4 sonnet"-version
  - calapsable text block with the used ASN GPT prompt, title "the prompt"
  - Add final blank line
  - Add the text "*end of document*"
  - Add final blank line

</details>

*end of document*