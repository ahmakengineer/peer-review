import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const skillPath = path.resolve(__dirname, '../../SKILL.md');

export default async () => ({
  config: (config) => {
    config.skills ??= {};
    config.skills.files ??= [];
    if (!config.skills.files.includes(skillPath)) {
      config.skills.files.push(skillPath);
    }
  },
});
