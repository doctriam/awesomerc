#!/bin/sh

mv /$HOME/.config/awesome/themes/zenburn/zenburn-background.png /$HOME/.config/awesome/themes/zenburn/zenburn-background-temp.png
sleep 1
mv /$HOME/.config/awesome/themes/zenburn/zenburn-background2.png /$HOME/.config/awesome/themes/zenburn/zenburn-background.png
sleep 1
mv /$HOME/.config/awesome/themes/zenburn/zenburn-background-temp.png /$HOME/.config/awesome/themes/zenburn/zenburn-background2.png

echo "Press Modkey + CTRL + R to refresh Awesome WM"

