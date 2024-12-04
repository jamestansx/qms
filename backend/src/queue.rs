use std::cmp::Ordering;

use chrono::{NaiveDateTime, Utc};

#[derive(Debug, Eq, PartialEq)]
pub struct QueuePriority {
    pub queue_number: usize,
    pub age: usize,
    pub appointment_time: NaiveDateTime,
}

impl Ord for QueuePriority {
    fn cmp(&self, other: &Self) -> Ordering {
        // compare if patient is elderly
        if self.age >= 65 {
            return Ordering::Greater;
        } else if other.age >= 65 {
            return Ordering::Less;
        }

        // compare if appointment time is closer to current time
        let current_time = Utc::now().naive_utc();
        if let Ordering::Greater =
            (current_time - self.appointment_time).cmp(&(current_time - other.appointment_time))
        {
            return Ordering::Greater;
        };

        self.queue_number.cmp(&other.queue_number)
    }
}

impl PartialOrd for QueuePriority {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
