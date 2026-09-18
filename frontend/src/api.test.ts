import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { api, ApiError } from './api'

describe('api client', () => {
  beforeEach(() => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        status: 200,
        headers: new Headers({ 'content-type': 'application/json' }),
        json: async () => ({ token: 'jwt', email: 'a@b.com', fullName: 'A' }),
      }),
    )
  })

  afterEach(() => {
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  it('login posts credentials to auth endpoint', async () => {
    await api.login({ email: 'a@b.com', password: 'secret123' })

    expect(fetch).toHaveBeenCalledWith(
      'http://api.test/api/auth/login',
      expect.objectContaining({
        method: 'POST',
        body: JSON.stringify({ email: 'a@b.com', password: 'secret123' }),
      }),
    )
  })

  it('listTasks sends bearer token and query params', async () => {
    vi.mocked(fetch).mockResolvedValueOnce({
      ok: true,
      status: 200,
      headers: new Headers({ 'content-type': 'application/json' }),
      json: async () => [],
    } as Response)

    await api.listTasks('tok', 'TODO', 'demo')

    expect(fetch).toHaveBeenCalledWith(
      'http://api.test/api/tasks?status=TODO&search=demo',
      expect.objectContaining({
        headers: expect.any(Headers),
      }),
    )

    const init = vi.mocked(fetch).mock.calls[0][1] as RequestInit
    const headers = init.headers as Headers
    expect(headers.get('Authorization')).toBe('Bearer tok')
  })

  it('throws ApiError with server message on failure', async () => {
    vi.mocked(fetch).mockResolvedValueOnce({
      ok: false,
      status: 400,
      headers: new Headers({ 'content-type': 'application/json' }),
      json: async () => ({ message: 'Cet email est deja utilise' }),
    } as Response)

    await expect(
      api.register({
        email: 'a@b.com',
        password: 'secret123',
        fullName: 'A',
      }),
    ).rejects.toMatchObject({
      message: 'Cet email est deja utilise',
      status: 400,
    } satisfies Partial<ApiError>)
  })

  it('rejects non array task list payloads', async () => {
    vi.mocked(fetch).mockResolvedValueOnce({
      ok: true,
      status: 200,
      headers: new Headers({ 'content-type': 'application/json' }),
      json: async () => ({ tasks: [] }),
    } as Response)

    await expect(api.listTasks('tok')).rejects.toBeInstanceOf(ApiError)
  })

  it('treats 204 delete as success', async () => {
    vi.mocked(fetch).mockResolvedValueOnce({
      ok: true,
      status: 204,
      headers: new Headers(),
      json: async () => {
        throw new Error('no body')
      },
    } as Response)

    await expect(api.deleteTask('tok', 7)).resolves.toBeUndefined()
  })
})
