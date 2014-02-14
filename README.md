A Dotty Grid environment
========================

Designed to support creative maths.

Getting Started (Developers)
---

Install [NodeJs](http://nodejs.org/) and [Grunt](http://gruntjs.com/), then:

```
git clone https://github.com/gmp26/DottyGrid.git
cd DottyGrid
npm install && bower install
grunt server
```

The third step downloads and compiles development dependencies so you will see
a lot of network traffic.

Chrome will open pointing to a copy of the animation at http://localhost:9000.

Notes
---

* `grunt server:dist` will create a publication ready, minified and optimised distribution in dist.
* This animation uses Bootstrap v3 and Angular-ui/bootstrap-bower latest.

Credits
---
* Thanks to Byron Knoll for the [Visibility Polygon algorithm](https://code.google.com/p/visibility-polygon-js/) and [Demo](http://www.byronknoll.com/visibility.html).
