export type TaskStatus = 'TODO' | 'IN_PROGRESS' | 'DONE'

export interface AuthUser {
  email: string
  fullName: string
  token: string
}

export interface Task {
  id: number
  title: string
  description: string | null
  status: TaskStatus
  createdAt: string
  updatedAt: string
}

export interface TaskPayload {
  title: string
  description: string
  status: TaskStatus
}
