macro_rules! keyed_enum {
    ($(#[$meta:meta])* $name:ident { $($variant:ident => $key:literal),+ $(,)? } default $default:ident) => {
        $(#[$meta])*
        #[derive(Debug, Clone, Copy, PartialEq, Eq)]
        pub enum $name {
            $($variant),+
        }

        impl Default for $name {
            fn default() -> Self {
                Self::$default
            }
        }

        impl $name {
            pub fn key(self) -> &'static str {
                match self {
                    $(Self::$variant => $key),+
                }
            }

            pub fn parse(text: &str) -> Option<Self> {
                match text {
                    $($key => Some(Self::$variant),)+
                    _ => None,
                }
            }
        }
    };
}

pub(super) use keyed_enum;
