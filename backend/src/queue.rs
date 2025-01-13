use std::cmp::{self, Ordering};

use chrono::{Duration, NaiveDateTime, Utc};

#[derive(Eq, PartialEq, Debug, Clone, Copy)]
pub struct QueuePriority {
    pub current: bool,
    pub queue_no: usize,
    pub age: usize,
    pub appointment_time_utc: NaiveDateTime,
}

#[derive(Debug, Eq, PartialEq, Hash, Clone, Copy)]
pub struct Queue {
    pub appointment_uuid: uuid::Uuid,
    pub wearable_uuid: Option<uuid::Uuid>,
}

impl Ord for QueuePriority {
    /// The queue priority is calculated based on the following criteria:
    /// 1. Age - elderly (age >= 65) has a greater priority
    /// 2. Appointment Time - appointment within 1 hours will be prioritized
    /// 3. Queue number
    fn cmp(&self, other: &Self) -> cmp::Ordering {
        if self.current {
            return Ordering::Greater;
        }

        let elder = (self.age >= 65, other.age >= 65);
        if elder.0 && !elder.1 {
            return Ordering::Greater;
        } else if elder.1 && !elder.0 {
            return Ordering::Less;
        }

        let current_time = Utc::now().naive_utc();
        let range_limit = current_time + Duration::hours(1);
        if self.appointment_time_utc > range_limit {
            return Ordering::Less;
        } else if other.appointment_time_utc > range_limit {
            return Ordering::Greater;
        }

        other.queue_no.cmp(&self.queue_no)
    }
}

impl PartialOrd for QueuePriority {
    fn partial_cmp(&self, other: &Self) -> Option<cmp::Ordering> {
        Some(self.cmp(other))
    }
}
