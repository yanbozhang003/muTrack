import numpy as np
import matplotlib.pyplot as plt 

phase = np.linspace(0, np.pi, num=5)
phase[3:] += np.pi
phase_unwrap = np.unwrap(phase, discont=2*np.pi)


plt.plot(phase_unwrap)
plt.show()