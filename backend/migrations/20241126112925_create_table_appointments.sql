CREATE TABLE appointments (
	id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	patient_id INTEGER NOT NULL,
	scheduled_at_utc DATETIME NOT NULL,
	updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

	FOREIGN KEY(patient_id) REFERENCES patients(id)
	ON DELETE CASCADE
	ON UPDATE NO ACTION
);

CREATE INDEX appointment_index ON appointments(patient_id);
