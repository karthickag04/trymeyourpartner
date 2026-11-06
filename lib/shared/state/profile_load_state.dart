/// Where the signed-in member's own profile is in loading. "No profile" is
/// only known once a load has succeeded; a failed load is not "no profile".
enum ProfileLoadState { notLoaded, loading, loaded, failed }
