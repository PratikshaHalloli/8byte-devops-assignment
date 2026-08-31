const request = require('supertest');
const app = require('../index');

describe('GET /health', () => {
  it('should return HTTP 200 OK and status UP', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual('UP');
  });
});
