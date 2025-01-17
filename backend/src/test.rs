#[cfg(test)]
mod tests {
    use chrono::{Duration, Utc};
    use priority_queue::PriorityQueue;

    use crate::queue::QueuePriority;

    #[test]
    fn test_queue() {
        let mut queue = PriorityQueue::<String, QueuePriority>::new();

        let current_patient = QueuePriority {
            current: true,
            queue_no: 1,
            age: 32,
            appointment_time_utc: Utc::now().naive_utc() + Duration::minutes(15),
        };

        let elderly = QueuePriority {
            current: false,
            queue_no: 4,
            age: 69,
            appointment_time_utc: Utc::now().naive_utc() + Duration::minutes(30),
        };

        let third = QueuePriority {
            current: false,
            queue_no: 3,
            age: 23,
            appointment_time_utc: Utc::now().naive_utc() + Duration::minutes(30),
        };

        let second = QueuePriority {
            current: false,
            queue_no: 2,
            age: 23,
            appointment_time_utc: Utc::now().naive_utc() + Duration::hours(2),
        };

        queue.push("current".into(), current_patient);
        queue.push("2nd".into(), second);
        queue.push("3rd".into(), third);
        queue.push("4th".into(), elderly);

        assert!(queue.into_sorted_vec() == ["current", "4th", "3rd", "2nd"]);
    }
}
