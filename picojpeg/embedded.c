#include "../bareBench.h"

//-------------------------------------------------------------------
//-------------------------------------------------------------------

int run_test ( void );

int main ( void )
{
    unsigned int result = run_test();
    ee_printf("%u\n", result);
    return(0);
}
