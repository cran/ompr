context("MIP: model")

test_that("only max and min are valid directions for an objective function", {
  m <- add_variable(MIPModel(), x[i], i = 1:10, type = "binary")
  expect_error(set_objective(m, x[1] + x[3], sense = "wat"))
  set_objective(m, x[1] + x[3], sense = "min")
  set_objective(m, x[1] + x[3], sense = "max")
})

test_that("all symbols in an obj. function need to be variables", {
  m <- add_variable(MIPModel(), x[i], i = 1:2, type = "binary")
  expect_error(set_objective(m, x[5], sense = "min"))
})

test_that("set_objective throws an error if it is non-linear", {
  m <- add_variable(MIPModel(), x[i], i = 1:3, type = "binary")
  expect_error(set_objective(m, sum_expr(x[i], i = 1:2) * x[3]))
})

test_that("we can solve a model", {
  m <- add_variable(MIPModel(), x[i], i = 1:3, type = "binary")
  m <- add_constraint(m, sum_expr(x[i], i = 1:3) == 1)
  m <- set_objective(m, x[1])
  solution <- new_solution(m, 0, "optimal", solution = c())
  result <- solve_model(m, function(model) {
    expect_identical(model, m)
    solution
  })
  expect_identical(result, solution)
})

test_that("it works with magrittr pipes", {
  m <- add_variable(MIPModel(), x[i], i = 1:3, type = "binary") %>%
    add_constraint(sum_expr(x[i], i = 1:3) == 1) %>%
    set_objective(x[1])
  expect_equal(length(m$variables), 1)
})

test_that("set_object passes external values to sum_expr", {
  max_bins <- 5
  m <- MIPModel()
  m <- add_variable(m, y[i], i = 1:max_bins, type = "binary")
  expect_silent(m <- set_objective(m, sum_expr(y[i], i = 1:max_bins), "min"))
})

test_that("we can model a tsp", {
  cities <- 3
  distance_matrix <- as.matrix(dist(1:cities, diag = TRUE, upper = TRUE))
  sub_tours <- list(1, 2, 3, c(1, 2), c(1, 3), c(2, 3))
  expect_silent(
    r <- MIPModel() %>%
      add_variable(x[i, j], i = 1:cities, j = 1:cities, type = "binary") %>%
      set_objective(sum_expr(distance_matrix[i, j] * x[i, j],
        i = 1:cities, j = 1:cities
      ), sense = "min") %>%
      add_constraint(x[i, i] == 0, i = 1:cities) %>%
      add_constraint(x[i, j] == x[j, i], i = 1:cities, j = 1:cities) %>%
      add_constraint(sum_expr(x[i, j], i = sub_tours[[s]], j = sub_tours[[s]]) <=
        length(sub_tours[s]) - 1, s = 1:length(sub_tours))
  )
})

test_that("bug 20160701: -x as a formula", {
  expect_silent(add_variable(MIPModel(), x, type = "continuous", lb = 4) %>%
    add_variable(y, type = "continuous", ub = 4) %>%
    add_constraint(x + y <= 10) %>%
    set_objective(-x + y, sense = "max"))
})

test_that("model has a nice default output", {
  m <- add_variable(MIPModel(), x, type = "continuous", lb = 4) %>%
    add_variable(y, type = "continuous", ub = 4) %>%
    add_constraint(x + y <= 10) %>%
    set_objective(-x + y, sense = "max")
  expect_output(print(m), "Constraints: 1")
})

test_that("model outputs direction on print", {
  m <- set_objective(add_variable(MIPModel(), x), 0, sense = "max")
  expect_output(print(m), "maximize")
  m <- set_objective(add_variable(MIPModel(), x), 0, sense = "min")
  expect_output(print(m), "minimize")
})


test_that("bug 20161011 #83: bounds of binary vars are not 0/1", {
  model <- add_variable(MIPModel(), x, type = "binary") %>%
    add_constraint(x <= 10) %>%
    set_objective(-x, sense = "max")
  expect_equal(model$variable_bounds_lower, 0)
  expect_equal(model$variable_bounds_upper, 1)
})

test_that("multiplications in objective fun", {
  m <- add_variable(MIPModel(), x, type = "continuous", lb = 4) %>%
    add_variable(y, type = "continuous", ub = 4) %>%
    add_constraint(x + y <= 10) %>%
    set_objective(5 * (-x + y), sense = "max")
  expect_equal(m$objective$fun$constant, 0)
  expect_equal(terms_list(m$objective$fun)[["1"]]$coefficient, -5)
  expect_equal(terms_list(m$objective$fun)[["2"]]$coefficient, 5)
})

test_that("model output works without an obj. function", {
  m <- add_variable(MIPModel(), x, type = "continuous", lb = 4)
  expect_output(show(m))
})

test_that("small to mid sized models should work", {
  n <- 400
  expect_silent(result <- MIPModel() %>%
    add_variable(x[i], i = 1:n, type = "binary") %>%
    set_objective(sum_expr(x[i], i = 1:n), "max") %>%
    add_constraint(sum_expr(x[i], i = 1:n) == 1))
})

test_that("bug 20160713 #41: quantifiers in constraints in sum_expr", {
  expect_silent(MIPModel() %>%
    add_variable(x[i], i = 1:9) %>%
    add_constraint(sum_expr(x[i], i = 1:3 + y) == 1, y = c(0, 3, 6)))
})

test_that("bug 20160729: two sum_expr on one side", {
  expect_silent({
    m <- MIPModel() %>%
      add_variable(x[j], j = 1:4) %>%
      add_constraint(sum_expr(x[j], j = 1:2) - sum_expr(x[j], j = 3:4) == 0)
  })
})

test_that("solve_model warns about wrong arguments", {
  m <- MIPModel()
  expect_error(solve_model(m, not_a_fun <- 0), regexp = "function")
})

test_that("set_objective_ supports standard eval.", {
  m <- MIPModel()
  m <- add_variable_(m, ~x)
  expect_silent(m <- set_objective_(m, ~x))
})

test_that("can expand a term N * (x - y)", {
  m <- add_variable(MIPModel(), x[i], i = 1:2)
  expect_silent(
    set_objective_(m, ~ -5 * (x[1] - x[2]))
  )
})

test_that("evaluates terms", {
  m <- add_variable(MIPModel(), x[i], i = 1:2)
  m <- set_objective_(m, ~ 5 * 5)
  expect_equal(25, m$objective$fun)
})

test_that("SE handles sum_expr well", {
  expect_silent({
    MIPModel() %>%
      add_variable_(~ x[j], j = 1:4) %>%
      add_constraint_(~ sum_expr(x[j], j = 1:2, j == 1) -
        sum_expr(x[j], j = 3:4) == 0)
  })
})

test_that("bug 20161110 #106: Error when indices used in sum_expr(...)
           condition already have values in workspace", {
  i <- 2
  j <- 2
  model <- MIPModel()
  model <- add_variable(model, x[i, j], i = 1:2, j = 1:2, i != j)
  expect_silent(result <- set_objective(
    model,
    sum_expr(x[i, j],
      i = 1:2,
      j = 1:2, i != j
    )
  ))
  expect_silent(result <- add_constraint(
    model,
    sum_expr(x[i, j],
      i = 1:2,
      j = 1:2, i != j
    ) <= 10
  ))
  expect_silent(result <- add_constraint(
    model,
    sum_expr(1 + x[i, j] + x[i, j],
      i = 1:2, j = 1:2,
      i != j
    ) <= 10
  ))
})

test_that("MIPModel supports a numeric objective", {
  model <- MIPModel()
  model <- add_variable(model, x[i, j], i = 1:2, j = 1:2, i != j)
  model <- set_objective(model, 42)
  res <- objective_function(model)
  expect_equal(res$constant, 42)
})

test_that("MIPModel edge case work", {
  model <- MIPModel()
  model <- add_variable(model, x[i, j], i = 1:2, j = 1:2, i != j)
  model <- set_objective(model, x[1, 2] + x[1, 2] + x[1, 2] + x[1, 2])
  res <- objective_function(model)
  expect_equal(res$constant, 0)
  expect_equal(as.numeric(res$solution), c(4, 0))
})

test_that("MIPModel add_variable signals some errors", {
  model <- MIPModel()
  model <- add_variable(model, x[i, j], i = 1:2, j = 1:2, i != j)
  expect_error(
    add_variable(model, x[i, j], i = 1:2, j = 1:2, i != j),
    "already"
  )
  expect_error(
    add_variable(model, sum(x), i = 1:2, j = 1:2, i != j),
    "form"
  )
})

test_that("Adding constraints with no variables works", {
  model <- MIPModel() %>%
    add_variable(x[i], i = 1:10) %>%
    add_constraint(sum_over(x[i], i = 1:10, i < 1) <= 10)
  expect_equal(length(model$constraints), 0)
})

test_that("An error is thrown if a constraint is false", {
  expect_error(
    MIPModel() %>%
      add_variable(x[i], i = 1:10) %>%
      add_constraint(sum_over(x[i], i = 1:10, i < 1) + 100 <= 10),
    "true"
  )
})

test_that("constraint senses are correct", {
  model <- MIPModel() %>%
    add_variable(x) %>%
    add_constraint(x <= 10) %>%
    add_constraint(x == 10) %>%
    add_constraint(x >= 10)
  expect_s3_class(model$constraints[[1]]$sense, "LinearConstraintSenseLeq")
  expect_s3_class(model$constraints[[2]]$sense, "LinearConstraintSenseEq")
  expect_s3_class(model$constraints[[3]]$sense, "LinearConstraintSenseGeq")
  expect_equal(model$constraints[[1]]$sense$sense, "<=")
  expect_equal(model$constraints[[2]]$sense$sense, "==")
  expect_equal(model$constraints[[3]]$sense$sense, ">=")
})
