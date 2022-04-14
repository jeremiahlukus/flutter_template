#!/usr/bin/env bash

GIT_DIR=$(git rev-parse --git-dir)

echo "Installing hooks..."
# this command creates symlink to our pre-commit script
rm -f $GIT_DIR/hooks/pre-commit
cp pre-commit $GIT_DIR/hooks/pre-commit
chmod +x .git/hooks/pre-commit
echo "Done!"
