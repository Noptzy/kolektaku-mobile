use domain::download::{DownloadJob, DownloadPhase, DownloadTarget};

use super::port::DownloadProgress;

pub const INTERRUPTED: &str = "interrupted when the app closed";

#[derive(Debug, Default, Clone)]
pub struct JobBoard {
    jobs: Vec<DownloadJob>,
}

impl JobBoard {
    pub fn from_saved(saved: Vec<DownloadJob>) -> (Self, Vec<DownloadJob>) {
        let mut interrupted = Vec::new();
        let jobs = saved
            .into_iter()
            .map(|mut job| {
                if job.phase.is_active() {
                    job.phase = DownloadPhase::Failed;
                    job.error = Some(INTERRUPTED.into());
                    interrupted.push(job.clone());
                }
                job
            })
            .collect();
        (Self { jobs }, interrupted)
    }

    pub fn list(&self) -> Vec<DownloadJob> {
        let mut jobs = self.jobs.clone();
        jobs.sort_by(|left, right| {
            right
                .created_at_secs
                .cmp(&left.created_at_secs)
                .then(right.id.cmp(&left.id))
        });
        jobs
    }

    pub fn get(&self, id: i64) -> Option<DownloadJob> {
        self.jobs.iter().find(|job| job.id == id).cloned()
    }

    pub fn for_episode(&self, target: &DownloadTarget) -> Option<DownloadJob> {
        self.jobs
            .iter()
            .find(|job| job.target.is_same_episode(target))
            .cloned()
    }

    pub fn next_queued(&self) -> Option<DownloadJob> {
        self.jobs
            .iter()
            .filter(|job| job.phase == DownloadPhase::Queued)
            .min_by_key(|job| (job.created_at_secs, job.id))
            .cloned()
    }

    pub fn put(&mut self, job: DownloadJob) {
        match self.jobs.iter_mut().find(|known| known.id == job.id) {
            Some(known) => *known = job,
            None => self.jobs.push(job),
        }
    }

    pub fn remove(&mut self, id: i64) -> Option<DownloadJob> {
        let index = self.jobs.iter().position(|job| job.id == id)?;
        Some(self.jobs.remove(index))
    }

    pub fn progress(&mut self, id: i64, progress: DownloadProgress) {
        if let Some(job) = self
            .jobs
            .iter_mut()
            .find(|job| job.id == id && job.phase.is_active())
        {
            job.phase = progress.phase;
            job.progress = progress.fraction.clamp(0.0, 1.0);
            job.bytes = progress.bytes;
        }
    }
}

#[cfg(test)]
mod tests {
    use domain::media::{MediaId, MediaKind, MediaRef};
    use domain::stream::StreamSet;

    use super::*;

    fn job(id: i64, episode: f64, phase: DownloadPhase, created: u64) -> DownloadJob {
        let target = DownloadTarget {
            media: MediaRef::catalog(MediaId::new(1).unwrap()),
            kind: MediaKind::Anime,
            title: "A".into(),
            episode,
            cover_url: None,
        };
        let stream = StreamSet {
            sources: Vec::new(),
            poster_url: None,
            headers: Vec::new(),
            subtitles: Vec::new(),
            skips: Vec::new(),
        };
        let mut job = DownloadJob::queued(target, stream, created);
        job.id = id;
        job.phase = phase;
        job
    }

    #[test]
    fn downloads_cut_off_by_a_restart_are_marked_failed_so_they_can_be_retried() {
        let (board, interrupted) = JobBoard::from_saved(vec![
            job(1, 1.0, DownloadPhase::Fetching, 1),
            job(2, 2.0, DownloadPhase::Done, 2),
        ]);
        assert_eq!(interrupted.len(), 1);
        assert_eq!(board.get(1).unwrap().phase, DownloadPhase::Failed);
        assert_eq!(board.get(2).unwrap().phase, DownloadPhase::Done);
    }

    #[test]
    fn the_list_is_newest_first_and_the_oldest_waiting_job_runs_next() {
        let mut board = JobBoard::default();
        board.put(job(1, 1.0, DownloadPhase::Queued, 10));
        board.put(job(2, 2.0, DownloadPhase::Queued, 20));
        board.put(job(3, 3.0, DownloadPhase::Done, 5));
        let order: Vec<i64> = board.list().iter().map(|job| job.id).collect();
        assert_eq!(order, vec![2, 1, 3]);
        assert_eq!(board.next_queued().unwrap().id, 1);
    }

    #[test]
    fn progress_only_moves_an_active_job() {
        let mut board = JobBoard::default();
        board.put(job(1, 1.0, DownloadPhase::Queued, 1));
        board.put(job(2, 2.0, DownloadPhase::Done, 1));
        let step = DownloadProgress {
            phase: DownloadPhase::Fetching,
            fraction: 1.5,
            bytes: 9,
        };
        board.progress(1, step);
        board.progress(2, step);
        assert_eq!(board.get(1).unwrap().progress, 1.0);
        assert_eq!(board.get(1).unwrap().phase, DownloadPhase::Fetching);
        assert_eq!(board.get(2).unwrap().phase, DownloadPhase::Done);
    }

    #[test]
    fn an_episode_already_on_the_board_is_found_and_can_be_removed() {
        let mut board = JobBoard::default();
        let first = job(1, 4.0, DownloadPhase::Queued, 1);
        board.put(first.clone());
        assert_eq!(board.for_episode(&first.target).unwrap().id, 1);
        assert!(board.remove(1).is_some());
        assert!(board.remove(1).is_none());
    }
}
