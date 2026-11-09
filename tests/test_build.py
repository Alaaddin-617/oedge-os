import unittest

from tools.build import IMAGE_SIZE, KERNEL_LIMIT, SECTOR_SIZE, create_image


class CreateImageTests(unittest.TestCase):
    def setUp(self):
        self.boot = bytes(SECTOR_SIZE - 2) + b"\x55\xaa"

    def test_builds_a_1440_kib_floppy_image(self):
        kernel = b"kernel"
        image = create_image(self.boot, kernel)

        self.assertEqual(len(image), IMAGE_SIZE)
        self.assertEqual(image[:SECTOR_SIZE], self.boot)
        self.assertEqual(image[SECTOR_SIZE : SECTOR_SIZE + len(kernel)], kernel)
        self.assertEqual(image[SECTOR_SIZE + len(kernel) :], bytes(IMAGE_SIZE - SECTOR_SIZE - len(kernel)))

    def test_rejects_a_malformed_boot_sector(self):
        with self.assertRaisesRegex(ValueError, "exactly 512 bytes"):
            create_image(b"short", b"")

    def test_rejects_a_boot_sector_without_signature(self):
        with self.assertRaisesRegex(ValueError, "0x55AA"):
            create_image(bytes(SECTOR_SIZE), b"")

    def test_rejects_a_kernel_larger_than_the_boot_loader_reads(self):
        with self.assertRaisesRegex(ValueError, "maximum"):
            create_image(self.boot, bytes(KERNEL_LIMIT + 1))


if __name__ == "__main__":
    unittest.main()
