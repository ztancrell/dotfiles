#!/bin/bash
# Play logout sound then exit labwc

paplay ~/.config/labwc/sound/service-logout.oga
sleep 0.5
labwc --exit
