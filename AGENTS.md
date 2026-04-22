# Agent guidance for this Drupal site

This codebase is a Composer-managed Drupal 11 site. Local development uses `ddev`.
Production runs on TransIP shared hosting under the `dvborgercompagnienl` account.

## Project facts

- Drupal core: 11 (installed with `standard` profile)
- Admin theme: Gin
- Frontend theme: Olivero (standaard Drupal)
- PHP platform: pinned to 8.3 in `composer.json` (TransIP server runs PHP 8.3)
- Config sync directory: `config/sync/` (set in `web/sites/default/settings.php`)
- Drush is in `require` (not `require-dev`) so it is available on the production server
- GitHub repo: https://github.com/bond708/pure-frustratie

## Contrib modules

Installed contrib modules (all in `web/modules/contrib/`):

- `admin_toolbar` + `admin_toolbar_tools` — dropdown admin menu
- `easy_breadcrumb` — breadcrumb navigation
- `field_group` — group fields in forms and displays
- `gin_login` + `gin_toolbar` — Gin admin theme extensions
- `google_tag` — Google Tag Manager / Analytics integration
- `honeypot` — spam protection for forms
- `linkit` — rich link picker in WYSIWYG
- `media_file_delete` — delete files when media entities are deleted
- `menu_link_attributes` — extra attributes on menu links
- `metatag` — SEO meta tags
- `pathauto` — automatic URL aliases (requires `token`)
- `redirect` — 301 redirects on URL changes
- `scheduler` — schedule content publish/unpublish
- `search_api` — extensible search framework
- `simple_sitemap` — XML sitemap
- `svg_image` — SVG support in image fields
- `token` — token system (dependency for pathauto)
- `webform` + `webform_ui` — form builder

## Local environment (DDEV)

Run commands from the project root:

- Start or restart the local environment with `ddev start`, `ddev restart`, and `ddev stop`.
- Install PHP dependencies with `ddev composer install`.
- Open the site with `ddev launch`.
- Run Drush commands with `ddev drush <command>` such as `status`, `user:login`, `cache:rebuild`, and `update:db`.

DDEV project config lives in `.ddev/config.yaml`. Use `.ddev/config.local.yaml` for machine-specific overrides.

## Common Drupal workflows

- Add a module with `ddev composer require drupal/<project>`, then `ddev drush pm:enable --yes <module_machine_name>`, then `ddev drush cache:rebuild`.
- Apply database updates after code changes with `ddev drush update:db --yes`.
- Import repository configuration into the site with `ddev drush config:import --yes`.
- Export site configuration back to the repo with `ddev drush config:export --yes`.

## Deployment to TransIP

**Never run `./scripts/deploy.sh` without explicit confirmation from the user.**

Deployment is done via a local shell script because TransIP blocks GitHub Actions IPs for SSH.

- Run `./scripts/deploy.sh` to deploy `main` to production.
- The script does on the server: `git pull` → `composer install --no-dev` → `drush updb` → `drush cim` → `drush cr`.
- Required SSH key: `~/.ssh/id_ed25519_pure-frustratie_deploy` (already added to the server's `authorized_keys`).
- SSH gateway: `dvborgercompagnienl@dvborg.ssh.transip.me`.
- Remote path: `/data/sites/web/dvborgercompagnienl/subsites/pure-frustratie.nl/`.
- Production URL: https://pure-frustratie.nl

Standard release flow:

1. Make changes locally.
2. `ddev drush config:export --yes`
3. `git add -A && git commit -m "..." && git push origin main`
4. `./scripts/deploy.sh`

## Guardrails

- Do not commit secrets or machine-local overrides such as `.env`, `settings.local.php`, `settings.php`, or `.ddev/config.local.yaml`.
- Do not commit `vendor/` or uploaded files under `web/sites/*/files`.
- Do not edit Drupal core or contributed projects in place.
- Put custom code in `web/modules/custom` and `web/themes/custom`.
- When adding composer packages, keep `platform.php` at `8.3` (do not bump unless the production server is upgraded).
- Never run `drush site:install` against production — it drops all tables.

## References

- https://docs.ddev.com/en/stable/
- https://www.drupal.org/docs/administering-a-drupal-site/configuration-management/workflow-using-drush
