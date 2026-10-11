# ANN and SVM model fitting/tuning helpers.

one_hot_encode <- function(labels, class_levels) {
  labels <- as.character(labels)
  result <- vapply(class_levels, function(value) as.numeric(labels == value), numeric(length(labels)))
  if (length(class_levels) == 1L) result <- matrix(result, ncol = 1L)
  colnames(result) <- class_levels
  result
}

ann_predictions_to_classes <- function(predictions, class_levels) {
  predictions <- as.matrix(predictions)
  class_levels[max.col(predictions, ties.method = "first")]
}

fit_ann <- function(train, output, features, hidden, iterations, seed) {
  .require_namespace("RSNNS")
  class_levels <- levels(train[[output]])
  x <- as.matrix(train[, features, drop = FALSE])
  y <- one_hot_encode(train[[output]], class_levels)
  set.seed(seed)
  model <- RSNNS::mlp(
    x = x,
    y = y,
    size = as.integer(hidden),
    maxit = as.integer(iterations),
    hiddenActFunc = "Act_Logistic",
    outputActFunc = "Act_Logistic"
  )
  list(model = model, classes = class_levels)
}

predict_ann <- function(fit, new_data, features) {
  predictions <- predict(fit$model, as.matrix(new_data[, features, drop = FALSE]))
  ann_predictions_to_classes(predictions, fit$classes)
}

score_ann <- function(train, validation, output, features, hidden, iterations, seed) {
  fit <- fit_ann(train, output, features, hidden, iterations, seed)
  macro_recall(predict_ann(fit, validation, features), validation[[output]])
}

tune_ann <- function(train, validation, output, features, seed = 2019L,
                     max_iterations = 2000L, max_hidden_multiplier = 2L) {
  n_classes <- nlevels(train[[output]])
  initial_hidden <- max(1L, n_classes)

  iteration_candidates <- seq.int(200L, max(200L, max_iterations), by = 200L)
  best_iterations <- iteration_candidates[[1L]]
  best_iteration_score <- -Inf
  for (iterations in iteration_candidates) {
    score <- score_ann(train, validation, output, features, initial_hidden, iterations, seed + iterations)
    if (score >= best_iteration_score) {
      best_iteration_score <- score
      best_iterations <- iterations
    } else {
      break
    }
  }

  max_hidden <- max(1L, as.integer(max_hidden_multiplier) * n_classes)
  best_hidden1 <- 1L
  best_one_layer_score <- -Inf
  for (hidden1 in seq_len(max_hidden)) {
    score <- score_ann(train, validation, output, features, hidden1, best_iterations, seed + 10000L + hidden1)
    if (score > best_one_layer_score) {
      best_one_layer_score <- score
      best_hidden1 <- hidden1
    }
  }

  best_hidden2 <- 0L
  best_two_layer_score <- -Inf
  for (hidden2 in seq_len(max_hidden)) {
    score <- score_ann(
      train, validation, output, features,
      c(best_hidden1, hidden2), best_iterations,
      seed + 20000L + hidden2
    )
    if (score > best_two_layer_score) {
      best_two_layer_score <- score
      best_hidden2 <- hidden2
    }
  }

  hidden <- if (best_two_layer_score > best_one_layer_score) c(best_hidden1, best_hidden2) else best_hidden1
  list(
    iterations = best_iterations,
    hidden = hidden,
    validation_score = max(best_one_layer_score, best_two_layer_score)
  )
}

fit_polynomial_svm <- function(train, output, features, degree, scale, offset, seed) {
  .require_namespace("kernlab")
  set.seed(seed)
  kernlab::ksvm(
    x = make_formula(output, features),
    data = train,
    type = "C-svc",
    kernel = "polydot",
    scaled = rep(FALSE, length(features)),
    tol = 1e-3,
    shrinking = TRUE,
    fit = TRUE,
    kpar = list(degree = degree, scale = scale, offset = offset)
  )
}

score_polynomial_svm <- function(train, validation, output, features, degree, scale, offset, seed) {
  model <- fit_polynomial_svm(train, output, features, degree, scale, offset, seed)
  predictions <- predict(model, validation[, features, drop = FALSE])
  macro_recall(predictions, validation[[output]])
}

tune_polynomial_svm <- function(train, validation, output, features, seed = 2019L,
                                max_degree = 6L, max_scale = 6L, max_offset = 6L) {
  best_degree <- 1L
  best_offset <- 1L
  best_score <- -Inf

  # Historical code increased offset for each degree until validation stopped
  # improving, then increased degree. Keep that search shape, but bound it.
  for (degree in seq_len(max(1L, max_degree))) {
    local_best_score <- -Inf
    local_best_offset <- 1L
    previous <- -Inf
    for (offset in seq_len(max(1L, max_offset))) {
      score <- score_polynomial_svm(
        train, validation, output, features,
        degree = degree, scale = 1, offset = offset,
        seed = seed + 1000L * degree + offset
      )
      if (score > local_best_score) {
        local_best_score <- score
        local_best_offset <- offset
      }
      if (offset > 1L && score <= previous) break
      previous <- score
    }
    if (local_best_score > best_score) {
      best_score <- local_best_score
      best_degree <- degree
      best_offset <- local_best_offset
    } else if (degree > 1L) {
      break
    }
  }

  best_scale <- 1L
  previous <- best_score
  scale_candidates <- if (max_scale >= 2L) seq.int(2L, max_scale) else integer()
  for (scale in scale_candidates) {
    score <- score_polynomial_svm(
      train, validation, output, features,
      degree = best_degree, scale = scale, offset = best_offset,
      seed = seed + 50000L + scale
    )
    if (score > best_score) {
      best_score <- score
      best_scale <- scale
    }
    if (score <= previous) break
    previous <- score
  }

  list(
    degree = best_degree,
    scale = best_scale,
    offset = best_offset,
    validation_score = best_score
  )
}

fit_svm_kernel <- function(train, output, features, kernel, seed = 2019L, kpar = "automatic") {
  .require_namespace("kernlab")
  set.seed(seed)
  kernlab::ksvm(
    x = make_formula(output, features),
    data = train,
    type = "C-svc",
    kernel = kernel,
    scaled = rep(FALSE, length(features)),
    tol = 1e-3,
    shrinking = TRUE,
    fit = TRUE,
    kpar = kpar
  )
}
