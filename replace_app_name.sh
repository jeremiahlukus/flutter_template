find . -name '*.dart' -print0 | xargs -0 sed -i "" "s/flutter_template/new_app/g"
find . -name '*.yaml' -print0 | xargs -0 sed -i "" "s/flutter_template/new_app/g"
find . -name '*.lock' -print0 | xargs -0 sed -i "" "s/flutter_template/new_app/g"
find . -name '*.sh' -print0 | xargs -0 sed -i "" "s/flutter_template/new_app/g"
