module scripts

import os

pub fn install_from_scripts(apps map[string]string) ! {
	if apps.len == 0 {
		println('No script-based applications to install')
		return
	}

	println('\n=== Installing Script-Based Applications ===\n')
	println('⚠ Note: Some scripts may require user interaction')
	println('')

	mut successful := []string{}
	mut failed := []string{}

	mut index := 1
	total := apps.len

	for name, install_cmd in apps {
		println('[${index}/${total}] Installing: ${name}')
		println('  Command: ${install_cmd}')
		println('')

		exit_code := os.system(install_cmd)

		println('')
		if exit_code == 0 {
			println('  ✓ ${name} installed successfully')
			successful << name
		} else {
			println('  ✗ ${name} failed to install')
			println('    Exit code: ${exit_code}')
			failed << name
		}
		println('')
		index++
	}

	// Summary
	println('=== Script Installation Summary ===')
	println('Total applications: ${total}')
	println('Successful: ${successful.len}')
	if successful.len > 0 {
		for app in successful {
			println('  ✓ ${app}')
		}
	}

	if failed.len > 0 {
		println('\nFailed: ${failed.len}')
		for app in failed {
			println('  ✗ ${app}')
		}
		return error('${failed.len} script-based application(s) failed to install')
	}

	println('\n✓ Script installation process completed')
}
