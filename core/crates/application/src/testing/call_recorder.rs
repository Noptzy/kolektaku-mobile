use std::sync::Mutex;

use domain::error::SourceError;

#[derive(Default)]
pub struct CallRecorder {
    failure: Mutex<Option<SourceError>>,
    calls: Mutex<Vec<String>>,
}

impl CallRecorder {
    pub fn set_failure(&self, error: Option<SourceError>) {
        *self.failure.lock().unwrap() = error;
    }

    pub fn calls(&self) -> Vec<String> {
        self.calls.lock().unwrap().clone()
    }

    pub fn enter(&self, call: String) -> Result<(), SourceError> {
        self.calls.lock().unwrap().push(call);
        match &*self.failure.lock().unwrap() {
            Some(error) => Err(error.clone()),
            None => Ok(()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn records_every_call_in_order() {
        let recorder = CallRecorder::default();
        recorder.enter("first".into()).unwrap();
        recorder.enter("second".into()).unwrap();
        assert_eq!(recorder.calls(), vec!["first", "second"]);
    }

    #[test]
    fn fails_while_a_failure_is_set_and_still_records_the_call() {
        let recorder = CallRecorder::default();
        recorder.set_failure(Some(SourceError::Network("down".into())));
        assert!(recorder.enter("blocked".into()).is_err());
        recorder.set_failure(None);
        assert!(recorder.enter("allowed".into()).is_ok());
        assert_eq!(recorder.calls(), vec!["blocked", "allowed"]);
    }
}
