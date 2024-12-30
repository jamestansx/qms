CREATE TABLE appointments (
	appointment_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	uuid VARCHAR UNIQUE NOT NULL,
	patient_id INTEGER NOT NULL,
	scheduled_at_utc DATETIME NOT NULL,
	is_attended BOOLEAN DEFAULT false NOT NULL,
	FOREIGN KEY(patient_id) REFERENCES patients(patient_id)
	ON DELETE CASCADE
	ON UPDATE NO ACTION
);

CREATE INDEX idx_appointments_schedule ON appointments(scheduled_at_utc ASC);
CREATE UNIQUE INDEX idx_appointments_uuid ON appointments(uuid);
