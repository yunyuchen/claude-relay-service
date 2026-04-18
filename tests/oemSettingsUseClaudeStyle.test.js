const store = new Map()
const mockRedisClient = {
  get: jest.fn((k) => Promise.resolve(store.get(k) || null)),
  set: jest.fn((k, v) => {
    store.set(k, v)
    return Promise.resolve('OK')
  })
}

const mockRouter = {
  get: jest.fn(),
  post: jest.fn(),
  put: jest.fn(),
  delete: jest.fn()
}

jest.mock(
  'express',
  () => ({
    Router: () => mockRouter
  }),
  { virtual: true }
)

jest.mock('../src/models/redis', () => ({
  getClient: () => mockRedisClient,
  client: mockRedisClient
}))

jest.mock('../src/middleware/auth', () => ({
  authenticateAdmin: jest.fn((_req, _res, next) => next())
}))

jest.mock('../src/utils/logger', () => ({
  error: jest.fn(),
  warn: jest.fn(),
  info: jest.fn(),
  debug: jest.fn()
}))

jest.mock('../src/services/claudeCodeHeadersService', () => ({}))
jest.mock('../src/services/account/claudeAccountService', () => ({}))
jest.mock('../src/services/pricingService', () => ({
  pricingData: {},
  loadPricingData: jest.fn(),
  getStatus: jest.fn(),
  forceUpdate: jest.fn()
}))

jest.mock(
  '../config/config',
  () => ({
    ldap: { enabled: false }
  }),
  { virtual: true }
)

require('../src/routes/admin/system')

function createResponse() {
  const res = {
    statusCode: 200,
    body: null,
    json: jest.fn((payload) => {
      res.body = payload
      return res
    }),
    status: jest.fn((code) => {
      res.statusCode = code
      return res
    })
  }
  return res
}

function findGetHandler(path) {
  const call = mockRouter.get.mock.calls.find((c) => c[0] === path)
  // handler may be at index 1 (no middleware) or index 2 (with middleware)
  return call?.[call.length - 1]
}

function findPutHandler(path) {
  const call = mockRouter.put.mock.calls.find((c) => c[0] === path)
  return call?.[call.length - 1]
}

describe('OEM settings useClaudeStyleStats', () => {
  beforeEach(() => {
    store.clear()
    mockRedisClient.get.mockClear()
    mockRedisClient.set.mockClear()
    // Restore the store-backed implementations after clear
    mockRedisClient.get.mockImplementation((k) => Promise.resolve(store.get(k) || null))
    mockRedisClient.set.mockImplementation((k, v) => {
      store.set(k, v)
      return Promise.resolve('OK')
    })
  })

  test('GET /oem-settings 默认返回 useClaudeStyleStats=false', async () => {
    const handler = findGetHandler('/oem-settings')
    const res = createResponse()
    await handler({}, res)

    expect(res.body.success).toBe(true)
    expect(res.body.data.useClaudeStyleStats).toBe(false)
  })

  test('PUT /oem-settings 接受 useClaudeStyleStats=true 并回显', async () => {
    const putHandler = findPutHandler('/oem-settings')
    const getHandler = findGetHandler('/oem-settings')
    const resPut = createResponse()

    await putHandler({ body: { siteName: 'Test', useClaudeStyleStats: true } }, resPut)

    expect(resPut.statusCode).toBe(200)
    expect(resPut.body.data.useClaudeStyleStats).toBe(true)

    const resGet = createResponse()
    await getHandler({}, resGet)
    expect(resGet.body.data.useClaudeStyleStats).toBe(true)
  })

  test('PUT /oem-settings 未提供 useClaudeStyleStats 时默认 false', async () => {
    const putHandler = findPutHandler('/oem-settings')
    const resPut = createResponse()

    await putHandler({ body: { siteName: 'Test' } }, resPut)

    expect(resPut.body.data.useClaudeStyleStats).toBe(false)
  })
})
