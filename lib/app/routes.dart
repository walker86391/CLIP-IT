/// Route paths — single source of truth for navigation.
abstract final class Routes {
  static const loading = '/loading';
  static const auth = '/auth';
  static const ok = '/ok';

  // Legacy Step 0 placeholder routes (pages kept on disk, currently
  // unrouted — the tabbed /auth screen supersedes them).
  // static const signIn = '/sign-in';
  // static const signUp = '/sign-up';

  static const home = '/app/home';
  static const projects = '/app/projects';
  static const clips = '/app/clips';
  static const repurpose = '/app/repurpose';
  static const downloads = '/app/downloads';
  static const processing = '/app/processing';
  static const messages = '/app/messages';
  static const profile = '/app/profile';
  static const settings = '/app/settings';
}
