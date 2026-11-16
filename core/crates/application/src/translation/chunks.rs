use std::ops::Range;

pub const LINES_PER_REQUEST: usize = 200;
pub const BYTES_PER_REQUEST: usize = 16 * 1024;

pub fn chunk_by_limits(texts: &[String], max_lines: usize, max_bytes: usize) -> Vec<Range<usize>> {
    let mut chunks = Vec::new();
    let mut start = 0;
    let mut bytes = 0;
    for (index, text) in texts.iter().enumerate() {
        let size = text.len();
        let full = index - start >= max_lines || (index > start && bytes + size > max_bytes);
        if full {
            chunks.push(start..index);
            start = index;
            bytes = 0;
        }
        bytes += size;
    }
    if start < texts.len() {
        chunks.push(start..texts.len());
    }
    chunks
}

#[cfg(test)]
mod tests {
    use super::*;

    fn texts(count: usize, size: usize) -> Vec<String> {
        vec!["x".repeat(size); count]
    }

    #[test]
    fn nothing_makes_no_chunks() {
        assert!(chunk_by_limits(&[], 200, 16_384).is_empty());
    }

    #[test]
    fn a_short_list_is_one_chunk() {
        assert_eq!(chunk_by_limits(&texts(5, 10), 200, 16_384), vec![0..5]);
    }

    #[test]
    fn two_hundred_lines_fit_and_the_next_one_starts_a_new_chunk() {
        assert_eq!(chunk_by_limits(&texts(200, 1), 200, 16_384), vec![0..200]);
        assert_eq!(
            chunk_by_limits(&texts(201, 1), 200, 16_384),
            vec![0..200, 200..201]
        );
    }

    #[test]
    fn the_byte_limit_splits_before_it_is_crossed() {
        let chunks = chunk_by_limits(&texts(10, 1_000), 200, 3_500);
        assert_eq!(chunks, vec![0..3, 3..6, 6..9, 9..10]);
    }

    #[test]
    fn exactly_the_byte_limit_still_fits() {
        assert_eq!(chunk_by_limits(&texts(4, 1_000), 200, 4_000), vec![0..4]);
    }

    #[test]
    fn one_text_bigger_than_the_limit_travels_alone() {
        let mut list = texts(2, 10);
        list.insert(1, "y".repeat(5_000));
        assert_eq!(chunk_by_limits(&list, 200, 1_000), vec![0..1, 1..2, 2..3]);
    }

    #[test]
    fn the_chunks_cover_every_text_exactly_once() {
        let list = texts(777, 37);
        let chunks = chunk_by_limits(&list, 50, 1_500);
        let covered: usize = chunks.iter().map(|range| range.len()).sum();
        assert_eq!(covered, list.len());
        assert!(chunks.windows(2).all(|pair| pair[0].end == pair[1].start));
    }
}
