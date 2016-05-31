# [Neuroevo](https://github.com/giuse/neuroevo)

[![Gem Version](https://badge.fury.io/rb/neuroevo.svg)](https://badge.fury.io/rb/neuroevo)
[![Build Status](https://travis-ci.org/giuse/neuroevo.svg?branch=master)](https://travis-ci.org/giuse/neuroevo)
[![Code Climate](https://codeclimate.com/github/giuse/neuroevo/badges/gpa.svg)](https://codeclimate.com/github/giuse/neuroevo)


Born as working code I needed to import in a larger framework, this little gem constitutes a basic but de facto very usable neuroevolution framework.

I hope you'll find it extremely easy to start with. You're welcome to come play with me :)

5 main blocks compose it:
  
  - a linear algebra library, currently mostly NMatrix with few extensions
  - a neural network implementation, for the generic function approximator
  - a black-box optimizer, searching for the network's weights
  - a complex fitness setup (for starters, any callable object will do)
  - a solver / execution manager, easy to configure and extend

Choices are currently very limited (e.g. 2 networks and 2 optimizers), but as long as I will need this gem at work, it is guaranteed to grow.  
Collaborations are most welcome.

Check the spec for neuroevo to learn it bottom-up. Check the spec for solver to learn it top-down.  
If your business is backed by a Rails CMS, and linear regression is not sufficient to predict trends in your data, have it a go with `NNCurveFitting`. I am using it on my job, and am personally very happy with the results.

Hope it'll help your cause! Drop me a line if so :)
