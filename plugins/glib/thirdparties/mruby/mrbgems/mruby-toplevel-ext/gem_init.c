/*
 * This file is loading the irep
 * Ruby GEM code.
 *
 * IMPORTANT:
 *   This file was generated!
 *   All manual changes will get lost.
 */
#include <stdlib.h>
#include <mruby.h>
#include <mruby/irep.h>
#include <stdint.h>
#ifdef __cplusplus
extern const uint8_t gem_mrblib_irep_mruby_toplevel_ext[];
#endif
const uint8_t
#if defined __GNUC__
__attribute__((aligned(4)))
#elif defined _MSC_VER
__declspec(align(4))
#endif
gem_mrblib_irep_mruby_toplevel_ext[] = {
0x52,0x49,0x54,0x45,0x30,0x30,0x30,0x37,0x3c,0xe0,0x00,0x00,0x01,0x79,0x4d,0x41,
0x54,0x5a,0x30,0x30,0x30,0x30,0x49,0x52,0x45,0x50,0x00,0x00,0x01,0x1a,0x30,0x30,
0x30,0x32,0x00,0x00,0x00,0xfb,0x00,0x01,0x00,0x02,0x00,0x04,0x00,0x00,0x00,0x2e,
0x10,0x01,0x60,0x01,0x56,0x02,0x00,0x5d,0x01,0x00,0x10,0x01,0x60,0x01,0x56,0x02,
0x01,0x5d,0x01,0x01,0x10,0x01,0x60,0x01,0x56,0x02,0x02,0x5d,0x01,0x02,0x10,0x01,
0x60,0x01,0x56,0x02,0x03,0x5d,0x01,0x03,0x0e,0x01,0x03,0x37,0x01,0x67,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x04,0x00,0x07,0x69,0x6e,0x63,0x6c,0x75,0x64,0x65,0x00,
0x00,0x07,0x70,0x72,0x69,0x76,0x61,0x74,0x65,0x00,0x00,0x09,0x70,0x72,0x6f,0x74,
0x65,0x63,0x74,0x65,0x64,0x00,0x00,0x06,0x70,0x75,0x62,0x6c,0x69,0x63,0x00,0x00,
0x00,0x00,0x84,0x00,0x03,0x00,0x06,0x00,0x00,0x00,0x00,0x00,0x16,0x00,0x00,0x00,
0x33,0x00,0x10,0x00,0x10,0x03,0x2e,0x03,0x00,0x00,0x0f,0x04,0x01,0x05,0x01,0x48,
0x04,0x2c,0x03,0x01,0x37,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x00,0x05,
0x63,0x6c,0x61,0x73,0x73,0x00,0x00,0x07,0x69,0x6e,0x63,0x6c,0x75,0x64,0x65,0x00,
0x00,0x00,0x00,0x3a,0x00,0x03,0x00,0x04,0x00,0x00,0x00,0x00,0x00,0x08,0x00,0x00,
0x33,0x00,0x10,0x00,0x0f,0x03,0x37,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x3a,0x00,0x03,0x00,0x04,0x00,0x00,0x00,0x00,0x00,0x08,0x00,0x00,
0x33,0x00,0x10,0x00,0x0f,0x03,0x37,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x3a,0x00,0x03,0x00,0x04,0x00,0x00,0x00,0x00,0x00,0x08,0x00,0x00,
0x33,0x00,0x10,0x00,0x0f,0x03,0x37,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x4c,0x56,0x41,0x52,0x00,0x00,0x00,0x41,0x00,0x00,0x00,0x03,0x00,0x07,0x6d,0x6f,
0x64,0x75,0x6c,0x65,0x73,0x00,0x01,0x26,0x00,0x07,0x6d,0x65,0x74,0x68,0x6f,0x64,
0x73,0x00,0x00,0x00,0x01,0x00,0x01,0x00,0x02,0x00,0x02,0x00,0x01,0x00,0x01,0x00,
0x02,0x00,0x02,0x00,0x01,0x00,0x01,0x00,0x02,0x00,0x02,0x00,0x01,0x00,0x01,0x00,
0x02,0x45,0x4e,0x44,0x00,0x00,0x00,0x00,0x08,
};
void mrb_mruby_toplevel_ext_gem_init(mrb_state *mrb);
void mrb_mruby_toplevel_ext_gem_final(mrb_state *mrb);

void GENERATED_TMP_mrb_mruby_toplevel_ext_gem_init(mrb_state *mrb) {
  int ai = mrb_gc_arena_save(mrb);
  mrb_load_irep(mrb, gem_mrblib_irep_mruby_toplevel_ext);
  if (mrb->exc) {
    mrb_print_error(mrb);
    mrb_close(mrb);
    exit(EXIT_FAILURE);
  }
  mrb_gc_arena_restore(mrb, ai);
}

void GENERATED_TMP_mrb_mruby_toplevel_ext_gem_final(mrb_state *mrb) {
}
