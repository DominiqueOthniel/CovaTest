package com.taskmanager.dto;

import com.taskmanager.entity.TaskStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class TaskRequest {

	@NotBlank
	@Size(max = 200)
	private String title;

	@Size(max = 2000)
	private String description;

	@NotNull
	private TaskStatus status;
}
