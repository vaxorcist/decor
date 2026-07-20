#!/bin/bash
set -euo pipefail

mkdir -p export
cd export

cp ../app/models/site_text.rb                                  app@models@site_text@rb 2>/dev/null || echo "MISSING: app/models/site_text.rb"
cp ../app/controllers/site_texts_controller.rb                 app@controllers@site_texts_controller@rb 2>/dev/null || echo "MISSING: app/controllers/site_texts_controller.rb"
cp ../app/controllers/admin/site_texts_controller.rb            app@controllers@admin@site_texts_controller@rb
cp ../config/routes.rb                                          config@routes@rb
cp ../app/views/common/_navigation.html.erb                     app@views@common@_navigation@html.erb
cp ../app/views/layouts/admin.html.erb                          app@views@layouts@admin@html.erb
cp ../test/fixtures/site_texts.yml                              test@fixtures@site_texts@yml 2>/dev/null || echo "MISSING: test/fixtures/site_texts.yml"
cp ../test/controllers/admin/site_texts_controller_test.rb      test@controllers@admin@site_texts_controller_test@rb
cp ../db/schema.rb                                               db@schema@rb

# whatever views exist in these two directories - grab them all
for f in ../app/views/admin/site_texts/*; do
  [ -f "$f" ] && cp "$f" "app@views@admin@site_texts@$(basename "$f" | sed 's/\./@/g; s/@\([a-z]*\)$/.\1/')"
done
for f in ../app/views/site_texts/*; do
  [ -f "$f" ] && cp "$f" "app@views@site_texts@$(basename "$f" | sed 's/\./@/g; s/@\([a-z]*\)$/.\1/')"
done

echo "Done. Upload everything now in decor/export/"