import numpy as np
import matplotlib.pyplot as plt

x = np.array([0.0, 1.0, 2.0, 3.0, 4.0, 5.0])
y = np.array([0.0, 0.8, 2.2, 3.6, 3.9, 5.3])

p = np.polyfit(x,y,1)

x_fit = np.linspace(0,5,100)
y_fit = np.polyval(p,x_fit)

E_list = []
for idx in range(len(x)):
    x_tmp = x[idx]
    y_fit_tmp = np.polyval(p,x_tmp)
    E_list.append(y[idx]-y_fit_tmp)

E_vec = np.array(E_list)
E = np.sqrt(np.sum(np.square(E_vec)))
print(E)

plt.plot(x,y,'ko')
plt.plot(x_fit,y_fit,'k-')
plt.show()