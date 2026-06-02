# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
import jax
import jax.numpy as jnp

# Basic array
x = jnp.array([[1.0, 4.0, 7.0], [4.0, 9.0, 11.0]])
print(x)

# Confirm available devices
print(f"Devices: {jax.devices()}")


# Exercise jit + grad on a simple function
@jax.jit
def loss(params, x):
    return jnp.sum((params * x) ** 2)


grad_fn = jax.grad(loss)
print(grad_fn(jnp.array([1.0, 2.0, 3.0]), jnp.array([1.0, 1.0, 1.0])))
