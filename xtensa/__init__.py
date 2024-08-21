from support import readfile
from support.bsp_sources.target import Target


class Xtensa(Target):
    @property
    def name(self):
        return 'esp32'

    @property
    def target(self):
        return 'xtensa-esp32-elf'

    def has_libc(self, profile):
        return True

    @property
    def has_small_memory(self):
        return True

    @property
    def has_single_precision_fpu(self):
        return True

    @property
    def has_double_precision_fpu(self):
        return False

    def __init__(self):
        super(Xtensa, self).__init__()
        self.add_gnat_sources(
            'src/s-macres__native.adb',
            'src/s-textio__stdio.adb')

    def dump_runtime_xml(self, rts_name, rts):
        return readfile('xtensa/esp32/runtime.xml')

#    def amend_rts(self, rts_profile, conf):
#        None
#        #conf.build_flags['common_flags'] += ['-muser-mode']

    @property
    def system_ads(self):
        return {'light': 'system-xi-xtensa.ads'}
