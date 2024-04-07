import math

def wrapTo2Pi(Pha):
    if Pha >= 0:
        ret_Pha = Pha
    else:
        ret_Pha = Pha+2*math.pi
    return ret_Pha


phase1 = 0.25*math.pi
phase2 = -0.25*math.pi

pha1 = wrapTo2Pi(phase1)
pha2 = wrapTo2Pi(phase2)

print(pha1)
print(pha2)