CREATE TABLE IF NOT EXISTS bleBeacon (
	device_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	uuid VARCHAR UNIQUE NOT NULL,
	location_name VARCHAR UNIQUE NOT NULL
);

CREATE UNIQUE INDEX idx_location_id ON bleBeacon(uuid);
