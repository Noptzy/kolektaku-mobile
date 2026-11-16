use super::novel_title::is_novel_title_of;

fn names(titles: &[&str]) -> Vec<String> {
    titles.iter().map(|title| title.to_string()).collect()
}

#[test]
fn romanization_spacing_does_not_make_a_site_title_a_different_novel() {
    let targets = names(&["Yahari Ore no Seishun Love Come wa Machigatteiru."]);
    assert!(is_novel_title_of(
        &targets,
        "Yahari Ore no Seishun Love Come wa Machigatte Iru"
    ));
    assert!(is_novel_title_of(
        &targets,
        "Yahari Ore no Seishun Love Come wa Machigatteiru LN"
    ));
}

#[test]
fn a_prefix_must_end_on_a_word_boundary_even_when_spacing_is_ignored() {
    let targets = names(&["Yahari Ore no Seishun Love Come wa Machigatteiru. Zoku"]);
    assert!(is_novel_title_of(
        &targets,
        "Yahari Ore no Seishun Love Come wa Machigatte Iru"
    ));
    let other = names(&["Sword Art Online Progressive"]);
    assert!(!is_novel_title_of(&other, "Sword Art Onl"));
}

#[test]
fn a_long_title_that_differs_by_a_word_or_a_transliteration_is_still_the_same_novel() {
    let danmachi = names(&["Dungeon ni Deai wo Motomeru no wa Machigatteiru Darou ka"]);
    assert!(is_novel_title_of(
        &danmachi,
        "Dungeon ni Deai wo Motomeru no wa Machigatteiru no Darou ka"
    ));
    let alya = names(&["Tokidoki Bosotto Rossiya-go de Dereru Tonari no Alya-san"]);
    assert!(is_novel_title_of(
        &alya,
        "Tokidoki Bosotto Roshia-go de Dereru Tonari no Alya-san"
    ));
}

#[test]
fn side_stories_are_not_near_equal() {
    let danmachi = names(&["Dungeon ni Deai wo Motomeru no wa Machigatteiru Darou ka"]);
    assert!(!is_novel_title_of(
        &danmachi,
        "Dungeon ni Deai wo Motomeru no wa Machigatteiru no Darou ka Astrea Record"
    ));
    assert!(!is_novel_title_of(
        &danmachi,
        "Dungeon ni Deai wo Motomeru no wa Machigatteiru no Darou ka Gaiden Sword Oratoria"
    ));
}
