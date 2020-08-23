var assert = require('assert');
var app = require('../app.js');

describe('CheckTrue', function () {
    describe('#returnTrue()', function () {
        it('Should return true.', function () {
            assert.equal(app(), true);
        });
    });
});