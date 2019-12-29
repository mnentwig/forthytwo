// this file: validation of fixed point algorithms against C double precision as reference
// (no implementations on target platform in this file)

typedef struct _tol_t {
  double abstol;
  double reltol;
} tol_t;

void tol_init(tol_t* self){
  self->abstol = 1e-7;
  self->reltol = 1e-7;
}

#define max(a, b)((a) > (b) ? (a) : (b))
#define abs(a)(((a) < 0) ? -(a) : (a))
void tol_relax(tol_t* self, double valRef, int32_t valActual, double factor){
  double v = flm2double(valActual);
  self->abstol = max(self->abstol, factor * abs(v - valRef));
  self->reltol = max(self->reltol, factor * abs(v - valRef) / (abs(valRef) + 1e-15));
}

int tol_check(tol_t* self, double valRef, int32_t valActual){
    double v = flm2double(valActual);
    double abstol = max(self->abstol, abs(v - valRef));
    double reltol = max(self->reltol, abs(v - valRef) / (abs(valRef) + 1e-15));

    if ((abstol <= self->abstol) || ((reltol <= self->reltol)))
	return 1;

    if (abstol > self->abstol){
      printf("abstol fail. Expected %1.15f got %1.15f\n", valRef, v);
    }
    if (reltol > self->reltol){
      printf("reltol fail. Expected %1.15f got %1.15f\n", valRef, v);
    }
    return 0;
}

void flm_testAlg(){
  double v1;
  double v2;
  int32_t argA;
  int32_t argB;
  int32_t resPacked;
  tol_t tol;
    
  for (v1 = 2e-10; v1 < 2e9; v1 *= 1.01){
    //if (v1 < 0.000000157163043) continue;
    argA = double2flm(v1);
    for (v2 = 2e-10; v2 < 2e9; v2 *= 1.01){
      //if (v2 < 15761642.972850094000000) continue;
      //printf("v1: %1.15f v2: %1.15f\n", v1, v2);
      argB = double2flm(v2);
      
      tol_init(&tol);
      tol_relax(&tol, v1, argA, 2.0);
      tol_relax(&tol, v2, argB, 2.0);

      flm_add(argA, argB, &resPacked);
      //printf("%08x %08x %08x\n", argA, argB, resPacked);
      
      double resRef = v1 + v2;
      //double resImpl =  flm2double(resPacked);
      //printf("%1.15f\t%1.15f\n", resRef, resImpl);

      if (!tol_check(&tol, resRef, resPacked)){
	printf("tolcheck fail at v1: %1.15f v2: %1.15f\n", v1, v2);
	exit(EXIT_FAILURE);
      }
    }
  }
}
