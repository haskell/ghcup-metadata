import click

from packaging.version import parse
from pathlib import Path
from ruamel.yaml import YAML
from ruamel.yaml.comments import CommentedMap


@click.command()
@click.option('--metadata', 'metadata_file', type=click.Path(exists=True, path_type=Path), help='GHCup metadata file')
@click.option('--json', 'json_file', type=click.Path(exists=True, path_type=Path), help='The hls-metadata json')
@click.option('--out', 'out_file', type=click.Path(path_type=Path), help='The output file')
def inject_hls_install_info(metadata_file, json_file, out_file):
    yaml = YAML(typ='rt')

    metadata = yaml.load(metadata_file)
    json = yaml.load(json_file)

    for hls_ver, v_arch in json.items():
        seen_objects = []
        for myarch, v_plat in v_arch.items():
            for plat, ghc_vers in v_plat.items():
                dl_install_info = CommentedMap()
                if parse(hls_ver) < parse('1.7.0.0'):
                    dl_install_info['bindistFiles'] = {
                        'dataRules': [],
                        'exeRules': [
                            {'installSource': 'haskell-language-server-wrapper'},
                            *[
                                {'installSource': f'haskell-language-server-{v}'}
                                for v in ghc_vers
                            ],
                        ],
                        'exeSymLinked': [
                            {
                                'linkName': 'haskell-language-server-wrapper-${PKGVER}',
                                'pVPMajorLinks': False,
                                'setName': 'haskell-language-server-wrapper',
                                'target': 'haskell-language-server-wrapper'
                            },
                            *[{
                                'linkName': f'haskell-language-server-{v}~${{PKGVER}}',
                                'pVPMajorLinks': False,
                                'setName': f'haskell-language-server-{v}',
                                'target': f'haskell-language-server-{v}'
                            } for v in ghc_vers
                            ]
                        ],
                        'preserveMtimes': False
                    }
                else:
                    dl_install_info['bindistMake'] = {
                        'makeArgs': ['DESTDIR=${TMPDIR}', 'PREFIX=${PREFIX}', 'install'],
                        'exeSymLinked': [
                            {
                                'linkName': 'haskell-language-server-wrapper-${PKGVER}',
                                'pVPMajorLinks': False,
                                'setName': 'haskell-language-server-wrapper',
                                'target': 'bin/haskell-language-server-wrapper'
                            },
                            *[{
                                'linkName': f'haskell-language-server-{v}~${{PKGVER}}',
                                'pVPMajorLinks': False,
                                'setName': f'haskell-language-server-{v}',
                                'target': f'bin/haskell-language-server-{v}'
                            } for v in ghc_vers
                            ]
                        ],
                        'preserveMtimes': False
                    }

                # possibly add a new install-info object at the top of the metadata file
                if dl_install_info not in seen_objects:
                    cute_ver = hls_ver.replace('.', '')
                    if seen_objects:
                        anchor_name = f'hls-{cute_ver}-{myarch}-{plat}-install-info'
                    else:
                        anchor_name = f'hls-{cute_ver}-install-info'
                    dl_install_info.yaml_set_anchor(anchor_name, always_dump=True)

                    metadata.insert(0, f'.{anchor_name}', {'dlInstallInfo': dl_install_info})

                    seen_objects.append(dl_install_info)

                    active_obj = dl_install_info
                else:
                    active_obj = seen_objects[seen_objects.index(dl_install_info)]

                # now inject the dlInstallInfo in the HLS versions
                # because the original object has an achor, ruamel.yaml will
                # just add an alias here
                for os_ver, _ in (metadata['ghcupDownloads']['HLS'][hls_ver]['viArch'][myarch][plat]).items():
                    is_alias = False
                    for other_plat, other_node in v_plat.items():
                        if other_plat == plat:
                            continue
                        if v_plat[plat] is other_node:
                            is_alias = True
                            break

                    if not is_alias:
                        metadata['ghcupDownloads']['HLS'][hls_ver]['viArch'][myarch][plat][os_ver]['dlInstallInfo'] = active_obj

    yaml.width = 4096
    yaml.dump(metadata, out_file)


if __name__ == '__main__':
    inject_hls_install_info()
