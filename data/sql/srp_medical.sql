CREATE TABLE IF NOT EXISTS `player_medical_state` (
    `identifier` varchar(80) NOT NULL,
    `state_json` longtext NOT NULL,
    `stage` varchar(40) NOT NULL DEFAULT 'healthy',
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `medical_reports` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `patient_identifier` varchar(80) NOT NULL,
    `patient_name` varchar(120) NOT NULL,
    `provider_identifier` varchar(80) NOT NULL,
    `provider_name` varchar(120) NOT NULL,
    `department` varchar(120) DEFAULT NULL,
    `injuries_json` longtext,
    `treatments_json` longtext,
    `medications_json` longtext,
    `destination` varchar(160) DEFAULT NULL,
    `outcome` varchar(160) DEFAULT NULL,
    `narrative` text,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_medical_reports_patient` (`patient_identifier`),
    KEY `idx_medical_reports_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `player_certifications` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `identifier` varchar(80) NOT NULL,
    `certification` varchar(80) NOT NULL,
    `level` int NOT NULL DEFAULT 1,
    `granted_by` varchar(80) DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_player_cert` (`identifier`, `certification`),
    KEY `idx_player_cert_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `treatment_logs` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `identifier` varchar(80) NOT NULL,
    `provider_identifier` varchar(80) DEFAULT NULL,
    `provider_name` varchar(120) DEFAULT NULL,
    `treatment` varchar(100) NOT NULL,
    `result` varchar(60) DEFAULT NULL,
    `injury_id` varchar(80) DEFAULT NULL,
    `body_part` varchar(60) DEFAULT NULL,
    `notes` text,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_treatment_logs_identifier` (`identifier`),
    KEY `idx_treatment_logs_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
