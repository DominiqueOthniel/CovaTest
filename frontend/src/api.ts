import type { AuthUser, Task, TaskPayload, TaskStatus } from './types'

const API_BASE = (import.meta.env.VITE_API_URL ?? '').replace(/\/$/, '')

class ApiError extends Error {
  status: number

  constructor(message: string, status: number) {
    super(message)
    this.status = status
  }
}

async function request<T>(
  path: string,
  options: RequestInit = {},
  token?: string | null,
): Promise<T> {
  if (!API_BASE && import.meta.env.PROD) {
    throw new ApiError(
      'VITE_API_URL manquant au build. Configure la variable sur Railway puis redeploy.',
      500,
    )
  }

  const headers = new Headers(options.headers)
  headers.set('Content-Type', 'application/json')
  if (token) {
    headers.set('Authorization', `Bearer ${token}`)
  }

  const response = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers,
  })

  if (response.status === 204) {
    return undefined as T
  }

  const contentType = response.headers.get('content-type') || ''
  if (!contentType.includes('application/json')) {
    throw new ApiError(
      'Reponse API invalide. Verifie VITE_API_URL (URL du backend Railway).',
      response.status || 502,
    )
  }

  const data = await response.json().catch(() => null)
  if (!response.ok) {
    const message =
      data && typeof data === 'object' && 'message' in data
        ? String((data as { message: string }).message)
        : 'Une erreur est survenue'
    throw new ApiError(message, response.status)
  }
  return data as T
}

export const api = {
  register(payload: { email: string; password: string; fullName: string }) {
    return request<AuthUser>('/api/auth/register', {
      method: 'POST',
      body: JSON.stringify(payload),
    })
  },
  login(payload: { email: string; password: string }) {
    return request<AuthUser>('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify(payload),
    })
  },
  async listTasks(token: string, status?: TaskStatus | 'ALL', search?: string) {
    const params = new URLSearchParams()
    if (status && status !== 'ALL') params.set('status', status)
    if (search?.trim()) params.set('search', search.trim())
    const query = params.toString()
    const data = await request<Task[]>(`/api/tasks${query ? `?${query}` : ''}`, {}, token)
    if (!Array.isArray(data)) {
      throw new ApiError('Format de liste de taches invalide', 502)
    }
    return data
  },
  createTask(token: string, payload: TaskPayload) {
    return request<Task>('/api/tasks', {
      method: 'POST',
      body: JSON.stringify(payload),
    }, token)
  },
  updateTask(token: string, id: number, payload: TaskPayload) {
    return request<Task>(`/api/tasks/${id}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    }, token)
  },
  deleteTask(token: string, id: number) {
    return request<void>(`/api/tasks/${id}`, { method: 'DELETE' }, token)
  },
}

export { ApiError }
