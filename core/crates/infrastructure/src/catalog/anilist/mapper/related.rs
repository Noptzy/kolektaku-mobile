use domain::media::{MediaSummary, Relation, RelationType};

use super::summary::{is_visible, map_summary};
use crate::catalog::anilist::schema::{RawEdges, RawRecommendations, RawRelationEdge};

pub fn map_relations(raw: Option<RawEdges<RawRelationEdge>>) -> Vec<Relation> {
    raw.and_then(|edges| edges.edges)
        .unwrap_or_default()
        .into_iter()
        .filter_map(|edge| {
            let node = edge.node.filter(is_visible)?;
            Some(Relation {
                relation_type: edge.relation_type.unwrap_or(RelationType::Other),
                media: map_summary(node),
            })
        })
        .collect()
}

pub fn map_recommendations(raw: Option<RawRecommendations>) -> Vec<MediaSummary> {
    raw.and_then(|recommendations| recommendations.nodes)
        .unwrap_or_default()
        .into_iter()
        .filter_map(|node| node.media_recommendation)
        .filter(is_visible)
        .map(map_summary)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    const NODE: &str = r#"{"id":7,"type":"MANGA","title":{"romaji":"Source"},"format":"MANGA"}"#;
    const ADULT: &str = r#"{"id":8,"type":"MANGA","title":{"romaji":"Hidden"},"isAdult":true}"#;

    fn relations(edges: &str) -> Vec<Relation> {
        let json = format!(r#"{{"edges":{edges}}}"#);
        map_relations(Some(serde_json::from_str(&json).unwrap()))
    }

    #[test]
    fn keeps_the_relation_type_and_the_related_media() {
        let list = relations(&format!(
            r#"[{{"relationType":"ADAPTATION","node":{NODE}}}]"#
        ));
        assert_eq!(list[0].relation_type, RelationType::Adaptation);
        assert_eq!(list[0].media.title.romaji, "Source");
    }

    #[test]
    fn unknown_types_become_other_and_hidden_or_missing_nodes_are_skipped() {
        let list = relations(&format!(
            r#"[{{"relationType":"MYSTERY","node":{NODE}}},{{"relationType":"SEQUEL","node":{ADULT}}},{{"relationType":"PREQUEL","node":null}}]"#
        ));
        assert_eq!(list.len(), 1);
        assert_eq!(list[0].relation_type, RelationType::Other);
    }

    #[test]
    fn recommendations_skip_missing_and_adult_entries() {
        let json = format!(
            r#"{{"nodes":[{{"mediaRecommendation":{NODE}}},{{"mediaRecommendation":{ADULT}}},{{"mediaRecommendation":null}}]}}"#
        );
        let list = map_recommendations(Some(serde_json::from_str(&json).unwrap()));
        assert_eq!(list.len(), 1);
        assert!(map_recommendations(None).is_empty());
    }
}
