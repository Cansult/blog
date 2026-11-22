#!/bin/bash
set -x
set -e
hexo clean && hexo g
cd oi_posts
hexo clean && hexo g
cd ..
cp -R oi_posts/public public/oi_posts
hexo d
